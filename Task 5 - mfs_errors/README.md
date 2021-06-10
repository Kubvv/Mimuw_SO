Zadanie 5
Kontrolowane błędy danych

Niektórzy twierdza, że najcenniejszym fragmentem komputera nie jest żaden z jego fizycznych elementów, ale dane, które są zapisane na jego dyskach. Niestety zdarza się, że z różnych powodów (np. błąd programisty, błąd dysku, promieniowanie kosmiczne – zob. artykuł w Delcie) pojawiają się w nich niespodziewane błędy. Przetwarzając na komputerze ważne dane, warto zatem zastanowić się, czy w przypadku wystąpienia takiego błędu jest się w stanie go wykryć i przywrócić poprawne wartości. A najlepiej jest zawczasu przećwiczyć taki scenariusz, dlatego celem tego zadania jest przygotowanie prototypowej modyfikacji serwera mfs, obsługującego system plików MINIX (MINIX File System), wprowadzającej błędy w danych w znany i kontrolowany sposób.

W poniższym opisie słowo plik jest używane w znaczeniu zwykłego pliku, nie katalogu. Jeśli nie jest powiedziane inaczej, to modyfikacje w tym zadaniu dotyczą tylko obsługi plików (obsługa katalogów nie jest modyfikowana).
(A) Błędy w treści plików

Zmodyfikowany serwer mfs symuluje powstawanie błędów w treści plików przez zwiększanie o 1 (modulo 256) wartości zapisywanego bajtu, wprowadzając taki błąd w co trzecim zapisywanym bajcie każdego pliku. Liczone jest, który z kolei jest to zapisywany bajt (nie pozycja bajtu w pliku), począwszy od stworzenia pliku, aż do jego usunięcia (oznacza to m.in., że częstotliwość jest zachowywana po odmontowaniu dysku i zamontowaniu go ponownie w innej maszynie z tak samo zmodyfikowanym serwerem mfs). Częstotliwość liczona jest dla każdego pliku oddzielnie.

Przykład działania:

# ls
# echo '1234567' > ./plik1
# cat ./plik1
1244577
# echo '1234567' > ./plik2
# cat ./plik2
1244577
#

(B) Błędy w metadanych plików

Zmodyfikowany serwer mfs symuluje powstawanie błędów metadanych plików przez zmianę wartości bitu oznaczającego uprawnienia zapisu (write/w) dla innych użytkowników (others/o), wprowadzając taki błąd w co trzeciej operacji zmiany uprawnień pliku (chmod) realizowanej przez ten serwer plików. Wartość bitu zmieniana jest na przeciwną (0 na 1, 1 na 0) względem wartości ustawianej w tej operacji (nie względem dotychczasowej wartości uprawnień). Liczone jest, która z kolei jest to operacja, począwszy od uruchomienia tej instancji serwera mfs (np. poprzez zamontowanie partycji), aż do zakończenia działania tej instancji serwera (np. poprzez odmontowanie partycji). Częstotliwość nie jest liczona oddzielnie dla każdego pliku.

Przykład działania:

# ls -l
total 16
-rwxrwxr-x  1 root  operator  8 Apr 26 17:02 plik1
-rw-r--r--  1 root  operator  8 Apr 26 17:02 plik2
# chmod 777 ./plik1
# ls -l
total 16
-rwxrwxrwx  1 root  operator  8 Apr 26 17:02 plik1
-rw-r--r--  1 root  operator  8 Apr 26 17:02 plik2
# chmod 777 ./plik1
# ls -l
total 16
-rwxrwxrwx  1 root  operator  8 Apr 26 17:02 plik1
-rw-r--r--  1 root  operator  8 Apr 26 17:02 plik2
# chmod 777 ./plik1
# ls -l
total 16
-rwxrwxr-x  1 root  operator  8 Apr 26 17:02 plik1
-rw-r--r--  1 root  operator  8 Apr 26 17:02 plik2
# chmod 777 ./plik1
# ls -l
total 16
-rwxrwxrwx  1 root  operator  8 Apr 26 17:02 plik1
-rw-r--r--  1 root  operator  8 Apr 26 17:02 plik2
# chmod 777 ./plik2
# ls -l
total 16
-rwxrwxrwx  1 root  operator  8 Apr 26 17:02 plik1
-rwxrwxrwx  1 root  operator  8 Apr 26 17:02 plik2
# chmod 777 ./plik2
# ls -l
total 16
-rwxrwxrwx  1 root  operator  8 Apr 26 17:02 plik1
-rwxrwxr-x  1 root  operator  8 Apr 26 17:02 plik2
#

(C) Błędy w strukturze systemu plików

Zmodyfikowany serwer mfs symuluje powstawanie błędów w strukturze systemu plików przez przenoszenie usuwanych plików do podkatalogu debug, wprowadzając taki błąd w każdej operacji usuwania pliku, jeśli tylko w katalogu w którym znajduje się usuwany plik, znajduje się także katalog debug.

Przykład działania:

# ls
debug plik
# ls ./debug/
# rm ./plik
# ls
debug
# cd ./debug
# ls
plik
# rm ./plik
# ls
#

Wymagania i niewymagania

    Wszystkie pozostałe operacje realizowane przez serwer mfs, inne niż opisane powyżej, powinny działać bez zmian. Wymaganie to dotyczy operacji na poziomie serwera mfs (np. kopiowanie pliku za pomocą polecenia cp wykonywane jest m.in. za pomocą operacji odczytów i zapisów).
    Modyfikacje serwera nie mogą powodować błędów w systemie plików: ma być on zawsze poprawny i spójny.
    Dyski przygotowane i używane przez niezmodyfikowany serwer mfs powinny być poprawnymi dyskami także dla zmodyfikowanego serwera. Nie wymagamy natomiast odwrotnej kompatybilności, tzn. dyski używane poprzez zmodyfikowany serwer nie muszą działać poprawnie z niezmodyfikowanym serwerem.
    Modyfikacje mogą dotyczyć tylko serwera mfs (czyli mogą dotyczyć tylko plików w katalogu /usr/src/minix/fs/mfs).
    Podczas działania zmodyfikowany serwer nie może wypisywać żadnych dodatkowych informacji na konsolę ani do rejestru zdarzeń (ang. log).
    Można założyć, że w testowanych przypadkach użytkownik będzie miał wystarczające uprawnienia do wykonania wszystkich operacji.
    Można założyć, że w testowanych przypadkach w systemie plików będą tylko zwykłe pliki (nie łącza, nie pseudourządzenia itp.) i katalogi.
    Rozwiązanie nie musi być optymalne pod względem prędkości działania. Akceptowane będą rozwiązania, które działają bez zauważalnej dla użytkownika zwłoki.
    Można założyć, że na MINIX-e będzie zawsze ustawiona prawidłowa data i godzina, a rozwiązanie nie musi działać poprawnie przed 2021 i po 2037 roku oraz nie musi obsługiwać poprawnie dysków, na których znajdują się pliki stworzone, zmodyfikowane lub odczytane poza tym okresem.

Wskazówki

    Aby skompilować i zainstalować zmodyfikowany serwer mfs, należy wykonać make; make install w katalogu /usr/src/minix/fs/mfs. Takimi poleceniami będzie budowane i instalowane oddane rozwiązanie.

    Każde zamontowane położenie (ich listę wyświetli polecenie mount) obsługiwane jest przez nową instancję serwera mfs. Położenia zamontowane przed instalacją nowego serwera będą obsługiwane nadal przez jego starą wersję, więc aby przetestować na nich zmodyfikowany serwer, należy je odmontować i zamontować ponownie lub zrestartować system.

    Aby zmodyfikowany serwer obsługiwał też korzeń systemu plików (/), należy wykonać dodatkowe kroki, ale radzimy nie testować na nim (i nie wymagamy tego) zmodyfikowanego serwera mfs.

    Do MINIX-a uruchomionego pod QEMU można dołączać dodatkowe dyski twarde (i na nich testować swoje modyfikacje). Aby z tego skorzystać, należy:

    A. Na komputerze-gospodarzu stworzyć plik będący nowym dyskiem, np.: qemu-img create -f raw extra.img 1M.

    B. Podłączyć ten dysk do maszyny wirtualnej, dodając do parametrów, z jakimi uruchamiane jest QEMU, parametry -drive file=extra.img,format=raw,index=1,media=disk, gdzie parametr index określa numer kolejny dysku (0 to główny dysk – obraz naszej maszyny).

    C. Za pierwszym razem stworzyć na nowym dysku system plików mfs: /dev/c0d<numer kolejny dodanego dysku>, np. /sbin/mkfs.mfs /dev/c0d1.

    D. Stworzyć pusty katalog (np. mkdir /root/nowy) i zamontować do niego podłączony dysk: mount /dev/c0d1 /root/nowy.

    E. Wszystkie operacje wewnątrz tego katalogu będą realizowane na zamontowanym w tym położeniu dysku.

    F. Aby odmontować dysk, należy użyć polecenia umount /root/nowy.

    Tablica z funkcjami obsługiwanymi przez serwer mfs znajduje się w pliku table.c.

    W MINIX-ie małe ilości informacji przekazuje się między procesami poprzez wiadomości (zob. Laboratorium 7), natomiast większe porcje danych poprzez niskopoziomową pamięć dzieloną – tzw. granty (zob. punkt 4.2 w Laboratorium 7).

    Szukając miejsca do przechowywania na dysku dodatkowych informacji o zapisanych na nim plikach, można skorzystać z wymagania poprawnego działania systemu plików tylko od 2021 do 2037 roku.

    Implementacja serwera mfs nie jest omawiana na zajęciach, ponieważ jednym z celów tego zadania jest samodzielne przeanalizowanie odpowiednich fragmentów kodu źródłowego MINIX-a. Rozwiązując to zadanie, należy więcej kodu przeczytać, niż samodzielnie napisać lub zmodyfikować.

Rozwiązanie

Poniżej przyjmujemy, że ab123456 oznacza identyfikator studenta rozwiązującego zadanie. Należy przygotować łatkę (ang. patch) ze zmianami. Plik o nazwie ab123456.patch uzyskujemy za pomocą polecenia diff -rupNEZbB, tak jak w zadaniu 3. Łatka będzie aplikowana przez umieszczenie jej w katalogu / nowej kopii MINIX-a i wykonanie polecenia patch -p1 < ab123456.patch. Należy zadbać, aby łatka zawierała tylko niezbędne różnice. Na Moodle należy umieścić tylko łatkę ze zmianami.
Ocenianie

Oceniana będą zarówno poprawność, jak i styl rozwiązania. Podstawą do oceny rozwiązania będą testy automatyczne sprawdzające poprawność implementacji oraz przejrzenie kodu przez sprawdzającego. Za poprawną i w dobrym stylu implementację funkcjonalności opisanych w punktach (A), (B) i (C) rozwiązanie otrzyma odpowiednio: 2 pkt., 1 pkt i 2 pkt. Rozwiązanie, w którym łatka nie nakłada się poprawnie, które nie kompiluje się lub powoduje kernel panic podczas uruchamiania, otrzyma 0 pkt.
