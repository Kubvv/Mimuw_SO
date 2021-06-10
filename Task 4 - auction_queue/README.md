Zadanie 4
Systemy operacyjne, zadanie 4
Treść

Celem zadania jest zaimplementowanie strategii szeregowania "lowest unique bid" oraz dodanie wywołania systemowego, które umożliwi procesom wybór tej strategii.

Każdy proces szeregowany tym algorytmem składa pewną ofertę (ang. bid), będącą liczbą całkowitą nieujemną, która powinna być przechowywana przez system operacyjny. Do wykonania zostaje wybrany proces, którego oferta jest najmniejszą liczbą niewskazaną przez żaden inny proces.

Wszystkie procesy szeregowane zgodnie z algorytmem "lowest unique bid" mają ten sam ustalony priorytet AUCTION_Q, co oznacza, że znajdują się w tej samej kolejce procesów gotowych do wykonania. W obrębie tej kolejki wybieramy proces do wykonania zgodnie z zasadami aukcji "lowest unique bid", tj. wybieramy proces, który złożył najmniejszą unikalną ofertę. Jeśli takiego procesu nie ma, to wybieramy dowolny proces, który złożył jedną z najwyższych ofert. Dla przykładu, jeśli w kolejce AUCTION_Q mamy procesy p1, p2, p3, p4, p5 i p6, które złożyły oferty odpowiednio 20, 40, 50, 60, 20 i 50, to najpierw wykona się proces p2 (jako że 40 to najmniejsza spośród unikalnych ofert), potem p4, następnie w dowolnej kolejności p3 i p6, a na koniec, w dowolnej kolejności p1 i p5. Należy zapewnić prawidłowe umieszczenie procesu w kolejce w czasie szeregowania.

Podczas działania procesy szeregowane zgodnie z nowym algorytmem nie zmieniają swojego priorytetu (kolejki) w odróżnieniu od zwykłych procesów szeregowanych domyślnie. Należy zadbać o to, aby zwykłym procesom nie był przydzielany priorytet AUCTION_Q.
Implementacja

Implementacja powinna zawierać:

    Definicję stałej AUCTION_Q = 8 określającej priorytet procesów szeregowanych algorytmem "lowest unique bid".
    Nową funkcję systemową: int setbid(int bid). Jeśli wartość parametru jest dodatnia, to szeregowanie procesu zostanie zmienione na algorytm "lowest unique bid" z ofertą równą bid. Wartość 0 oznacza, że proces rezygnuje z szeregowania "lowest unique bid" i wraca do szeregowania domyślnego.
    Funkcja powinna przekazywać jako wynik 0, jeśli metoda szeregowania została zmieniona pomyślnie, a −1 w przeciwnym przypadku. Jeśli wartość parametru nie jest prawidłowa (ujemna lub większa niż MAX_BID = 100), to errno przyjmuje wartość EINVAL. Jeśli proces, który chce zmienić metodę szeregowania na "lowest unique bid", jest już szeregowany zgodnie z tym algorytmem, to errno przyjmuje wartość EPERM. Podobnie powinno się stać, gdy proces, który chce zrezygnować z szeregowania "lowest unique bid", wcale nie jest nim szeregowany.
    Bezpośrednio za nagłówkiem każdej funkcji, która została dodana lub zmieniona, należy dodać komentarz /* so_2021 */.

Dopuszczamy zmiany w katalogach:

    /usr/src/minix/servers/sched,
    /usr/src/minix/servers/pm,
    /usr/src/minix/kernel,
    /usr/src/lib/libc/misc,
    /usr/src/minix/lib/libsys.

oraz w plikach nagłówkowych:

    /usr/src/minix/include/minix/com.h który będzie kopiowany do /usr/include/minix/com.h,
    /usr/src/minix/include/minix/callnr.h, który będzie kopiowany do /usr/include/minix/callnr.h,
    /usr/src/include/unistd.h, który będzie kopiowany do /usr/include/unistd.h,
    /usr/src/minix/include/minix/syslib.h, który będzie kopiowany do /usr/include/minix/syslib.h,
    /usr/src/minix/include/minix/ipc.h, który będzie kopiowany do /usr/include/minix/ipc.h,
    /usr/src/minix/include/minix/config.h, który będzie kopiowany do /usr/include/minix/config.h. 

Wskazówki

    Do zmieniania metody szeregowania można dodać nową funkcję systemową mikrojądra. Warto w tym przypadku wzorować się na przykład na funkcji do_schedule(). Można też próbować zmodyfikować tę funkcję.
    Przypominamy, że za wstawianie do kolejki procesów gotowych odpowiedzialne jest mikrojądro (/usr/src/minix/kernel/proc.c). Natomiast o wartości priorytetu decyduje serwer sched, który powinien dbać o to, aby zwykłym procesom nie przydzielić priorytetu AUCTION_Q.
    Nie trzeba (i nie jest zalecane) pisanie nowego serwera szeregującego. Można zmodyfikować domyślny serwer sched.
    Aby nowy algorytm szeregowania zaczął działać, należy wykonać make; make install w katalogu /usr/src/minix/servers/sched oraz w innych katalogach zawierających zmiany. Jeśli zmiany zawiera plik mproc.h w kodzie serwera pm, warto też wykonać te polecenia w innych katalogach wymienionych w treści zadania 3. Następnie trzeba zbudować nowy obraz jądra, czyli wykonać make do-hdboot w katalogu /usr/src/releasetools i zrestartować system. Gdyby obraz nie chciał się załadować lub wystąpił poważny błąd (kernel panic), należy przy starcie systemu wybrać opcję 6, która załaduje oryginalne jądro.

Rozwiązanie

Poniżej przyjmujemy, że ab123456 oznacza identyfikator studenta rozwiązującego zadanie. Należy przygotować łatkę (ang. patch) ze zmianami w katalogu /usr. Plik o nazwie ab123456.patch uzyskujemy za pomocą polecenia diff -rupNEZbB, tak jak w zadaniu 3. Będzie on aplikowany w katalogu / z opcją -p1.

Prosimy pamiętać o dodaniu odpowiednich komentarzy, ponieważ lista zmienionych funkcji uzyskana za pomocą polecenia grep -r so_2021 /usr/src będzie miała wpływ na ocenę zadania. Wystarczy, że każda funkcja pojawi się na liście tylko raz, więc nie potrzeba umieszczać komentarzy w plikach nagłówkowych.

Rozwiązanie w postaci łatki ab123456.patch należy umieścić w Moodle'u. Opcjonalnie można dołączyć plik README.

Uwaga: nie przyznajemy punktów za rozwiązanie, w którym łatka nie nakłada się poprawnie, które nie kompiluje się lub powoduje kernel panic podczas uruchamiania.
