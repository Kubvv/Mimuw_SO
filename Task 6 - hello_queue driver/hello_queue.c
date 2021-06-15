#include "hello_queue.h"
#include <minix/drivers.h>
#include <minix/chardriver.h>
#include <stdio.h>
#include <stdlib.h>
#include <minix/ds.h>
#include <minix/ioctl.h>
#include <sys/ioc_hello_queue.h>

/* function prototypes for the hello_queue driver */
static int hello_queue_open(devminor_t minor, int access, endpoint_t user_endpt);
static int hello_queue_close(devminor_t minor);
static ssize_t hello_queue_read(devminor_t minor, u64_t position, endpoint_t endpt,
    cp_grant_id_t grant, size_t size, int flags, cdev_id_t id);
static ssize_t hello_queue_write(devminor_t minor, u64_t pos, endpoint_t ep,
	cp_grant_id_t grant, size_t size, int flags, cdev_id_t id);
static int hello_queue_ioctl(devminor_t minor, unsigned long request, endpoint_t endpt,
	cp_grant_id_t grant, int flags, endpoint_t user_endpt, cdev_id_t id);

/* ioctl functions */
static int hello_queue_ioctl_hqiocres(unsigned long request, endpoint_t endpt, cp_grant_id_t grant, endpoint_t user_endpt);
static int hello_queue_ioctl_hqiocset(unsigned long request, endpoint_t endpt, cp_grant_id_t grant, endpoint_t user_endpt);
static int hello_queue_ioctl_hqiocxch(unsigned long request, endpoint_t endpt, cp_grant_id_t grant, endpoint_t user_endpt);
static int hello_queue_ioctl_hqiocdel(unsigned long request, endpoint_t endpt, cp_grant_id_t grant, endpoint_t user_endpt);

/* SEF functions and variables */
static void sef_local_startup(void);
static int sef_cb_init(int type, sef_init_info_t *info);
static int sef_cb_lu_state_save(int);
static int lu_state_restore(void);

/* helper functions */
static int alloc_queue(uint32_t size);
static int dealloc_queue();

static char* queue;
static uint32_t str_length;
static uint32_t buf_size;

/* entry points to the hello_queue driver */
static struct chardriver hello_queue =
{
    .cdr_open	= hello_queue_open,
    .cdr_close	= hello_queue_close,
    .cdr_read	= hello_queue_read,
	.cdr_write  = hello_queue_write,
	.cdr_ioctl  = hello_queue_ioctl,
};

/* alloc helper functions */

/* safely allocs twice as much memory until buf_size is bigger than passed size */
static int alloc_queue(uint32_t size) {
	char *tmp = queue;
	uint32_t old_size = buf_size;
	if (buf_size == 0) {
		free(queue);
		queue = (char*) malloc(sizeof(char));
		buf_size = 1;
	}
	while (size > buf_size) {
		queue = (char*) realloc(queue, buf_size * 2);
		if (!queue) {
			queue = tmp;
			buf_size = old_size;
			return ENOMEM;
		}
		buf_size *= 2;
	}
	return OK;
}

/* halves the size of the queue safely */
static int dealloc_queue() {
	char *tmp = (char*) realloc(queue, sizeof(char) * buf_size / 2);
	if (!tmp) {
		return ENOMEM;
	}
	buf_size /= 2;
	queue = tmp;
	return OK;
}

/* driver's basic functions */

static int hello_queue_open(devminor_t UNUSED(minor), int UNUSED(access), endpoint_t UNUSED(user_endpt)) {
	return OK;
}


static int hello_queue_close(devminor_t UNUSED(minor)) {
	return OK;
}

/* gives user a requested number of bytes from the beginning of the queue */
static int hello_queue_read(devminor_t UNUSED(minor), u64_t UNUSED(position), endpoint_t endpt,
	cp_grant_id_t grant, size_t size, int UNUSED(flags), cdev_id_t UNUSED(id)) {

	/* if there is nothing else to read just leave */
	int ret;
	if (str_length == 0) {
		if (buf_size != 0) {
			ret = dealloc_queue();
		}
		return 0;
	}

	char* tmp = queue;
	uint32_t j = 0;
	uint32_t i;

	/* adjust size if it's bigger than currently stored string */
	if (size > str_length) {
		size = str_length;
	}

	i = size;

	/* put message to grant */
	ret = sys_safecopyto(endpt, grant, 0, (vir_bytes) tmp, size);
	if (ret != OK) {
	    return ret;
	}

	/* adjust the queue so it begins with first non-read char */
	for (; i < str_length; i++) {
		tmp[j] = queue[i];
		j++;
	}
	for (; j < buf_size; j++) {
		tmp[j] = 0;
	}
	queue = tmp;
	str_length -= size;

	/* dealloc queue if the current string size is smaller or equal than one fourth of buffer size */
	if (str_length <= buf_size / 4) {
		ret = dealloc_queue();
	}

	return size;
}

static int hello_queue_write(devminor_t UNUSED(minor), u64_t UNUSED(position), endpoint_t endpt,
		cp_grant_id_t grant, size_t size, int UNUSED(flags), cdev_id_t UNUSED(id)) {

	int ret;
	uint32_t readbuf_len = 256;
	uint32_t to_read;
	uint32_t i;
	char buf[readbuf_len];

	/* if buffer is too small, allocate appropriate size */
	if (str_length + size > buf_size) {
		ret = alloc_queue(str_length + size);
		if (ret != OK) {
			return ret;
		}
	}

	/* read message from user using chunks */
	for (size_t offset = 0; offset < size; offset += to_read) {
	    if (size - offset < readbuf_len) {
	    	to_read = size - offset;
	    }
	    else {
	    	to_read = readbuf_len;
	    }

		ret = sys_safecopyfrom(endpt, grant, offset, (vir_bytes) buf, to_read);
	    if (ret != OK) {
	        return ret;
	    }

	    i = str_length;
	    for (uint32_t j = 0; j < to_read; j++) {
	    	queue[i] = buf[j];
	    	i++;
	    }

	    str_length += to_read;
	}

	return size;
}

/* ioctl functions */

/* frees current queue and creates a new, fresh one */
static int hello_queue_ioctl_hqiocres(unsigned long request, endpoint_t endpt,
	cp_grant_id_t grant, endpoint_t user_endpt) {

	char* tmp;
	tmp = (char*) malloc(sizeof(char) * buf_size);
	if (!tmp) {
		return ENOMEM;
	}

	str_length = DEVICE_SIZE;
	buf_size = DEVICE_SIZE;
	free(queue);
	queue = tmp;

	for (uint32_t i = 0; i < buf_size; i++) {
		queue[i] = 'x' + (i % 3);
	}

	return OK;
}

/* puts message given by user to the end of the queue */
static int hello_queue_ioctl_hqiocset(unsigned long request, endpoint_t endpt,
	cp_grant_id_t grant, endpoint_t user_endpt) {

	if (MSG_SIZE == 0) {
		/* leave if message is empty */
		return OK;
	}

	char msg[MSG_SIZE];
	uint32_t j = 0;
	uint32_t to_read;
	uint32_t i = 0;
	uint32_t readbuf_len = 256;
	char buf[readbuf_len];
	int ret;

	/* read message from user using chunks */
	for (size_t offset = 0; offset < MSG_SIZE; offset += to_read) {
	    if (MSG_SIZE - offset < readbuf_len) {
	    	to_read = MSG_SIZE - offset;
	    }
	    else {
	    	to_read = readbuf_len;
	    }

		ret = sys_safecopyfrom(endpt, grant, offset, (vir_bytes) buf, to_read);
	    if (ret != OK) {
	        return ret;
	    }

	    for (uint32_t j = 0; j < to_read; j++) {
	    	msg[i] = buf[j];
	    	i++;
		}
	}

	/* allocate more memory if message is bigger than the queue */
	if (MSG_SIZE > buf_size) {
		ret = alloc_queue(MSG_SIZE);
		if (ret != OK) {
			return ret;
		}
	}

	/* case when message is larger then current queue content, place the message at the beginning of queue */
	if (MSG_SIZE >= str_length) {
		for (uint32_t i = 0; i < MSG_SIZE; i++) {
			queue[i] = msg[i];
		}
		str_length = MSG_SIZE;
	}
	else { /* case when message is smaller, swap MSG_SIZE chars from end of queue */
		for (uint32_t i = str_length - MSG_SIZE; i < str_length; i++) {
			queue[i] = msg[j];
			j++;
		}
	}

	return OK;
}

/* changes all occurrences of given char to the second given char */
static int hello_queue_ioctl_hqiocxch(unsigned long request, endpoint_t endpt,
	cp_grant_id_t grant, endpoint_t user_endpt) {

	char swap[2];
	int ret = sys_safecopyfrom(endpt, grant, 0, (vir_bytes) swap, 2);
	if (ret != OK) {
		return ret;
	}

	for (uint32_t i = 0; i < str_length; i++) {
		if (queue[i] == swap[0]) {
			queue[i] = swap[1];
		}
	}

	return OK;
}

/* deletes every third element from queue and changes str_length accordingly */
static int hello_queue_ioctl_hqiocdel(unsigned long request, endpoint_t endpt,
	cp_grant_id_t grant, endpoint_t user_endpt) {

	uint32_t j = 0;
	uint32_t new_len;
	for (uint32_t i = 0; i < str_length; i++) {
		if (i % 3 != 2) {
			queue[j] = queue[i];
			j++;
		}
	}

	new_len = j;
	for (; j < str_length; j++) {
		queue[j] = 0;
	}

	str_length = new_len;

	return OK;
}

/* this function is responsible for ioctl management, calls appropriate function for given request or returns ENOTTY */
static int hello_queue_ioctl(devminor_t UNUSED(minor), unsigned long request, endpoint_t endpt,
	cp_grant_id_t grant, int UNUSED(flags), endpoint_t user_endpt, cdev_id_t UNUSED(id)) {

	switch(request) {
    	case HQIOCRES:
    		return hello_queue_ioctl_hqiocres(request, endpt, grant, user_endpt);
    	case HQIOCSET:
    		return hello_queue_ioctl_hqiocset(request, endpt, grant, user_endpt);
    	case HQIOCXCH:
    		return hello_queue_ioctl_hqiocxch(request, endpt, grant, user_endpt);
    	case HQIOCDEL:
    		return hello_queue_ioctl_hqiocdel(request, endpt, grant, user_endpt);
    	default:
    		return ENOTTY;
	}
}

/* saving and retrieving */

static int lu_state_restore() {
	uint32_t v, w;

	/* retrieving */
	ds_retrieve_u32("str_length", &v);
	ds_delete_u32("str_length");
	str_length = v;

	ds_retrieve_u32("buf_size", &w);
	ds_delete_u32("buf_size");
	buf_size = w;
	char tmp[w];

	/* mallocing 0 bytes makes no sense, change buffer size to one */
	if (buf_size == 0) {
		queue = (char*) malloc(sizeof(char));
		if (!queue) {
			return ENOMEM;
		}
		buf_size = 1;
	}
	else { /* malloc and copy contents of tmp */
		ds_retrieve_mem("queue", tmp, &w);
		ds_delete_mem("queue");
		queue = (char*) malloc(sizeof(char) * buf_size);
		if (!queue) {
			return ENOMEM;
		}
		for (uint32_t i = 0; i < buf_size; i++) {
			queue[i] = tmp[i];
		}
	}

	return OK;
}

static int sef_cb_lu_state_save(int UNUSED(state)) {
	ds_publish_u32("buf_size", buf_size, DSF_OVERWRITE);
	ds_publish_u32("str_length", str_length, DSF_OVERWRITE);
	if (buf_size != 0) {
		ds_publish_mem("queue", queue, buf_size, DSF_OVERWRITE);
	}

	free(queue);

	return OK;
}

/* sef basic setup */

static void sef_local_startup() {
    sef_setcb_init_fresh(sef_cb_init);
    sef_setcb_init_lu(sef_cb_init);
    sef_setcb_init_restart(sef_cb_init);

    sef_setcb_lu_prepare(sef_cb_lu_prepare_always_ready);
    sef_setcb_lu_state_isvalid(sef_cb_lu_state_isvalid_standard);
    sef_setcb_lu_state_save(sef_cb_lu_state_save);

    sef_startup();
}

/* hello_queue has just been freshly initialized, malloc and create default queue */
static int sef_init_fresh() {
	str_length = DEVICE_SIZE;
	buf_size = DEVICE_SIZE;
	queue = (char*) malloc(sizeof(char) * buf_size);
	if (!queue) {
		return ENOMEM;
	}

	for (uint32_t i = 0; i < buf_size; i++) {
		queue[i] = 'x' + (i % 3);
	}

	return OK;
}

/* initialize the hello_queue driver */
static int sef_cb_init(int type, sef_init_info_t *UNUSED(info)) {
    int do_announce_driver = TRUE;
    int ret;

    switch(type) {
        case SEF_INIT_FRESH:
        	ret = sef_init_fresh();
        break;

        case SEF_INIT_LU:
            ret = lu_state_restore();
            do_announce_driver = FALSE;
        break;

        case SEF_INIT_RESTART:
        	ret = lu_state_restore();
        break;
    }

    if (ret != OK) {
    	return ret;
    }

    if (do_announce_driver) {
        chardriver_announce();
    }

    return OK;
}

int main(void) {
    sef_local_startup();

    chardriver_task(&hello_queue);
    return OK;
}
