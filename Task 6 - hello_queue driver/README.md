 <div role="main"><span id="maincontent"></span><h2>Zadanie 6</h2><div id="intro" class="box py-3 generalbox boxaligncenter"><div class="no-overflow"><p><span style="color:red">Update: 2.06. Zmiany na czerwono (refresh zamienione na restart)</span>.</p>

<p>Biorąc za punkt wyjścia MINIX-owe sterowniki urządzeń umieszczone w katalogu
<code>/usr/src/minix/drivers/examples</code>, zaimplementuj sterownik urządzenia
<code>/dev/hello_queue</code> działający zgodnie z poniższą specyfikacją.</p>

<p>Działanie urządzenia będzie przypominać prymitywna kolejkę z dodatkowymi
operacjami.</p>

<p>W chwili początkowej urządzenie ma dysponować buforem o pojemności <code>DEVICE_SIZE</code>
bajtów. Stała ta jest zdefiniowana w dostarczanym przez nas pliku nagłówkowym
<code>hello_queue.h</code>. Zastrzegamy możliwość zmiany wartości tej stałej w testach.</p>

<p>Pamięć na bufor powinna być rezerwowana (i zwalniana) dynamicznie.</p>

<p>Po uruchomieniu sterownika poleceniem <code>service up …</code> wszystkie elementy bufora
mają zostać wypełnione wielokrotnością ciągu kodów ASCII liter <code>x</code>, <code>y</code>, i <code>z</code>.
Jeśli wielkość bufora nie jest podzielna przez 3, ostatnie wystąpienie ciągu
powinno zostać odpowiednio skrócone.</p>

<p>Czytanie z urządzenia za pomocą funkcji <code>read</code> ma powodować odczytanie wskazanej
liczby bajtów z początku kolejki. Gdy w kolejce nie znajduje się dostateczna
liczba bajtów, należy odpowiednio zredukować wartość parametru polecenia
czytania. Odczytane bajty usuwa się z kolejki. Kolejność odczytanych bajtów
powinna odpowiadać kolejności, w jakiej bajty te były wkładane do kolejki. Gdy
po odczytaniu wskazanego ciągu bajtów bufor będzie zajęty w co najwyżej jednej
czwartej, należy zmniejszyć jego rozmiar o połowę. W przypadku wielkości
nieparzystej, nowa rozmiar powinien zostać zaokrąglony w dół do wartości
całkowitej.</p>

<p>Operacja pisania do urządzenia za pomocą funkcji <code>write</code> powoduje zapisanie
wskazanego ciągu bajtów na końcu kolejki. Gdy rozmiar bufora nie wystarcza do
zapisania wskazanego ciągu, należy pojemność bufora podwajać, aż będzie
on wystarczająco duży na zapisanie całego ciągu.</p>

<p>Oprócz obsługi operacji czytania i pisania sterownik powinien implementować
również operację <code>ioctl</code> pozwalającą na wykonanie następujących komend:</p>

<ul>
<li><code>HQIOCRES</code> – Przywraca kolejkę do stanu początkowego – bufor powinien być
rozmiaru <code>DEVICE_SIZE</code> oraz wypełniony wielokrotnością ciągu <code>x</code>, <code>y</code>, i <code>z</code>.</li>
<li><code>HQIOCSET</code> – Przyjmuje <code>char[MSG_SIZE]</code> i umieszcza przekazany napis
w kolejce. Gdy rozmiar bufora jest nie mniejszy niż długość napisu, funkcja
podmienia <code>MSG_SIZE</code> znaków z końca kolejki. Jeżeli napis zaś jest dłuższy od
aktualnego rozmiaru bufora kolejki, to bufor powinien zostać powiększony tak
samo jak podczas pisania do urządzenia, a następnie napis powinien zostać
umieszczony w kolejce tak jak w pierwszym przypadku. Po operacji ostatni znak
przekazanego napisu powinien znajdować się na końcu kolejki.</li>
<li><code>HQIOCXCH</code> – Przyjmuje <code>char[2]</code> i zamienia wszystkie wystąpienia
w kolejce <code>char[0]</code> na <code>char[1]</code>.</li>
<li><code>HQIOCDEL</code> – Usuwa co trzeci element z kolejki, zaczynając operację od
początku kolejki (numerując elementy kolejki od 1, usuwamy elementy
o numerach 3, 6, 9, …). Rozmiar bufora powinien pozostać bez zmian.</li>
</ul>

<p>Stała <code>MSG_SIZE</code> jest zdefiniowana w dostarczanym przez nas pliku
nagłówkowym <code>ioc_hello_queue.h</code>. Zastrzegamy możliwość zmiany wartości tej
stałej w testach.</p>

<p>Wykonanie funkcji <code>lseek</code> nie powinno powodować zmian w działaniu urządzenia.</p>

<p>Ponadto urządzenie powinno zachowywać aktualny stan w przypadku przeprowadzenia
jego aktualizacji poleceniem <code>service update</code> oraz w przypadku restartu
poleceniem <span style="color:red">service restart</span>.</p>

<p>Rozwiązanie powinno składać się z pojedynczego pliku <code>hello_queue.c</code>.
Plik <code>hello_queue.c</code> wraz z dostarczonymi przez nas plikami <code>Makefile</code>
i <code>hello_queue.h</code> zostanie umieszczony
w katalogu <code>/usr/src/minix/drivers/hello_queue</code>.
Ponadto w katalogach <code>/usr/include/sys</code> oraz <code>/usr/src/minix/include/sys</code>
zostanie zostanie umieszczony plik <code>ioc_hello_queue.h</code>.
W pliku <code>/etc/system.conf</code> umieszczony zostanie poniższy wpis:</p>

<pre><code>service hello_queue
{
        system
                IRQCTL          # 19
                DEVIO           # 21
        ;
        ipc
                SYSTEM pm rs tty ds vm vfs
                pci inet lwip amddev
        ;
        uid 0;
};
</code></pre>

<p>Sterownik będzie kompilowany za pomocą dostarczonego przez nas <code>Makefile</code>.
W katalogu <code>/usr/src/minix/drivers/hello_queue</code> zostaną wykonane polecenia:</p>

<pre><code>make clean
make
make install

mknod /dev/hello_queue c 17 0

service up /service/hello_queue -dev /dev/hello_queue
service update /service/hello_queue
service down hello_queue
</code></pre>

<p>Przykład użycia z terminala:</p>

<pre><code># cat /dev/hello_queue
xyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxyzx
# echo "abcabcabcabc" &gt; /dev/hello_queue
# cat /dev/hello_queue
abcabcabcabc

</code></pre>

<p>Przykłady użycia funkcji <code>ioctl</code> dostarczamy w pliku <code>ioc_example.c</code>.</p>

<p>Rozwiązanie należy oddawać przez Moodle.
Ewentualne pytania również należy zadawać poprzez udostępnione tam forum.</p>
</div>
