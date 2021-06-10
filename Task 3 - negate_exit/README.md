Zadanie 3

Zadanie polega na dodaniu wywołania systemowego PM_NEGATEEXIT oraz funkcji bibliotecznej int negateexit(int negate). Funkcja powinna być zadeklarowana w pliku unistd.h.
Negacja kodu powrotu procesu

W MINIX-ie proces kończy działanie, wywołując _exit(status), gdzie status to kod powrotu procesu. Rodzic może odczytać kod powrotu swojego potomka, korzystając np. z wait. Powłoka umieszcza kod powrotu ostatnio zakończonego procesu w zmiennej $?. Chcemy umożliwić procesowi wpływanie na wartość kodu powrotu swojego i swoich nowo tworzonych dzieci.

Nowa funkcja int negateexit(int negate), gdy zostanie wywołana z parametrem różnym od zera, powoduje, że gdy proces wywołujący tę funkcję zakończy działanie z kodem zero, rodzic odczyta kod powrotu równy jeden, a gdy zakończy działanie z kodem różnym od zera – rodzic odczyta zero. Wywołanie tej funkcji z parametrem równym zeru przywraca standardową obsługę kodów powrotu.

Wartość zwracana przez tę funkcję to informacja o zachowaniu procesu przed wywołaniem funkcji: 0 oznacza, że kody powrotu nie były zmieniane, a 1 – że były negowane. Jeśli wystąpi jakiś błąd, należy zwrócić -1 i ustawić errno na odpowiednią wartość.

Nowo tworzony proces ma dziedziczyć aktualne zachowanie rodzica, natomiast przyszłe zmiany zachowania rodzica (wynikające z kolejnych wywołań negateexit()) nie mają wpływu na potomka.

Jeżeli proces kończy działanie w inny sposób, niż używając systemowego wywołania PM_EXIT (używanego przez funkcję _exit()), np. na skutek sygnału, to jego kod powrotu nie powinien zostać zmieniony.

Na początku działania systemu, w szczególności dla procesu init, kody powrotu nie mają być negowane.

Działanie funkcji negateexit() powinno polegać na użyciu nowego wywołania systemowego PM_NEGATEEXIT, które należy dodać do serwera PM. Do przekazania parametru należy zdefiniować własny typ komunikatu.
Format rozwiązania

Poniżej przyjmujemy, że ab123456 oznacza identyfikator studenta rozwiązującego zadanie. Należy przygotować łatkę (ang. patch) ze zmianami w katalogu /usr. Plik zawierający łatkę o nazwie ab123456.patch uzyskujemy za pomocą polecenia

diff -rupNEZbB oryginalne-źródła/usr/ moje-rozwiązanie/usr/ > ab123456.patch

gdzie oryginalne-źródła to ścieżka do niezmienionych źródeł MINIX-a, natomiast moje-rozwiązanie to ścieżka do źródeł MINIX-a zawierających rozwiązanie. Tak użyte polecenie diff rekurencyjnie przeskanuje pliki ze ścieżki oryginalne-źródła/usr, porówna je z plikami ze ścieżki moje-rozwiązanie/usr i wygeneruje plik ab123456.patch, który podsumowuje różnice. Tego pliku będziemy używać, aby automatycznie nanieść zmiany na czystą kopię MINIX-a, gdzie będą przeprowadzane testy rozwiązania. Więcej o poleceniu diff można dowiedzieć się z podręcznika (man diff).

Umieszczenie łatki w katalogu / na czystej kopii MINIX-a i wykonanie polecenia

patch -p1 < ab123456.patch

powinno skutkować naniesieniem wszystkich oczekiwanych zmian wymaganych przez rozwiązanie. Należy zadbać, aby łatka zawierała tylko niezbędne różnice.

Po naniesieniu łatki zostaną wykonane polecenia:

    make && make install w katalogach /usr/src/minix/fs/procfs, /usr/src/minix/servers/pm, /usr/src/minix/drivers/storage/ramdisk, /usr/src/minix/drivers/storage/memory oraz /usr/src/lib/libc,
    make do-hdboot w katalogu /usr/src/releasetools,
    reboot.

Rozwiązanie w postaci łatki ab123456.patch należy umieścić na Moodlu.
Uwagi

Serwer PM przechowuje informacje o procesach w tablicy mproc zadeklarowanej w pliku mproc.h.
Warto przeanalizować, jak PM realizuje wywołania systemowe. Więcej informacji o działaniu tego serwera będzie na laboratorium 7.
Należy samodzielnie przetestować rozwiązanie. Jeden z podstawowych scenariuszy jest następujący: uruchamiamy proces A, który włącza negowanie kodów powrotu, a następnie uruchamia proces B. Proces B uruchamia proces C, który kończy działanie z kodem 0, ale z powodu włączonego negowania proces B odbiera ten kod jako 1. Następnie proces A wyłącza negowanie kodów powrotu, proces B kończy się z kodem 1, który A odbiera jako 0, gdyż wyłączenie negowania w A nie ma wpływu na wcześniej uruchomione B.
    Nie przyznajemy punktów za rozwiązanie, w którym łatka nie nakłada się poprawnie, które nie kompiluje się lub które powoduje kernel panic podczas uruchamiania systemu.
