<div role="main"><span id="maincontent"></span><h2>Zadanie 5</h2><div id="intro" class="box py-3 generalbox boxaligncenter"><div class="no-overflow"><h1>Kontrolowane błędy danych</h1>

<p>Niektórzy twierdza, że najcenniejszym fragmentem komputera nie jest żaden z jego
fizycznych elementów, ale dane, które są zapisane na jego dyskach. Niestety
zdarza się, że z różnych powodów (np. błąd programisty, błąd dysku,
promieniowanie kosmiczne – zob. <a href="http://www.deltami.edu.pl/temat/informatyka/2012/09/30/Promieniowanie_kosmiczne/">artykuł w Delcie</a>)
pojawiają się w nich niespodziewane błędy. Przetwarzając na komputerze ważne
dane, warto zatem zastanowić się, czy w przypadku wystąpienia takiego błędu jest
się w stanie go wykryć i przywrócić poprawne wartości. A najlepiej jest zawczasu
przećwiczyć taki scenariusz, dlatego celem tego zadania jest przygotowanie
prototypowej modyfikacji serwera  <em>mfs</em>, obsługującego system plików MINIX
(MINIX File System), wprowadzającej błędy w danych w znany i kontrolowany sposób.</p>

<p>W poniższym opisie słowo <em>plik</em> jest używane w znaczeniu zwykłego pliku,
nie katalogu. Jeśli nie jest powiedziane inaczej, to modyfikacje w tym zadaniu
dotyczą tylko obsługi plików (obsługa katalogów nie jest modyfikowana).</p>

<h2>(A) Błędy w treści plików</h2>

<p>Zmodyfikowany serwer <em>mfs</em> symuluje powstawanie błędów w treści plików przez
zwiększanie o 1 (modulo 256) wartości zapisywanego bajtu, wprowadzając taki błąd
w co trzecim zapisywanym bajcie każdego pliku. Liczone jest, który z kolei jest
to zapisywany bajt (nie pozycja bajtu w pliku), począwszy od stworzenia pliku,
aż do jego usunięcia (oznacza to m.in., że częstotliwość jest zachowywana po
odmontowaniu dysku i zamontowaniu go ponownie w innej maszynie z tak samo
zmodyfikowanym serwerem <em>mfs</em>). Częstotliwość liczona jest dla każdego pliku
oddzielnie.</p>

<p>Przykład działania:</p>

<pre><code># ls
# echo '1234567' &gt; ./plik1
# cat ./plik1
1244577
# echo '1234567' &gt; ./plik2
# cat ./plik2
1244577
#
</code></pre>

<h2>(B) Błędy w metadanych plików</h2>

<p>Zmodyfikowany serwer <em>mfs</em> symuluje powstawanie błędów metadanych plików przez
zmianę wartości bitu oznaczającego uprawnienia zapisu (<em>write</em>/<em>w</em>) dla innych
użytkowników (<em>others</em>/<em>o</em>), wprowadzając taki błąd w co trzeciej operacji
zmiany uprawnień pliku (<em>chmod</em>) realizowanej przez ten serwer plików. Wartość
bitu zmieniana jest na przeciwną (<code>0</code> na <code>1</code>, <code>1</code> na <code>0</code>) względem wartości
ustawianej w tej operacji (nie względem dotychczasowej wartości uprawnień).
Liczone jest, która z kolei jest to operacja, począwszy od uruchomienia tej
instancji serwera <em>mfs</em> (np. poprzez zamontowanie partycji), aż do zakończenia
działania tej instancji serwera (np. poprzez odmontowanie partycji).
Częstotliwość nie jest liczona oddzielnie dla każdego pliku.</p>

<p>Przykład działania:</p>

<pre><code># ls -l
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
</code></pre>

<h2>(C) Błędy w strukturze systemu plików</h2>

<p>Zmodyfikowany serwer <em>mfs</em> symuluje powstawanie błędów w strukturze systemu
plików przez przenoszenie usuwanych plików do podkatalogu <code>debug</code>, wprowadzając
taki błąd w każdej operacji usuwania pliku, jeśli tylko w katalogu w którym
znajduje się usuwany plik, znajduje się także katalog <code>debug</code>.</p>

<p>Przykład działania:</p>

<pre><code># ls
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
</code></pre>

<h2>Wymagania i niewymagania</h2>

<ol>
<li>Wszystkie pozostałe operacje realizowane przez serwer <em>mfs</em>, inne niż opisane
powyżej, powinny działać bez zmian. Wymaganie to dotyczy operacji na poziomie
serwera <em>mfs</em> (np. kopiowanie pliku za pomocą polecenia <code>cp</code> wykonywane jest
m.in. za pomocą operacji odczytów i zapisów).</li>
<li>Modyfikacje serwera nie mogą powodować błędów w systemie plików: ma być on
zawsze poprawny i spójny.</li>
<li>Dyski przygotowane i używane przez niezmodyfikowany serwer <em>mfs</em> powinny być
poprawnymi dyskami także dla zmodyfikowanego serwera. Nie wymagamy natomiast
odwrotnej kompatybilności, tzn. dyski używane poprzez zmodyfikowany serwer nie
muszą działać poprawnie z niezmodyfikowanym serwerem.</li>
<li>Modyfikacje mogą dotyczyć tylko serwera <em>mfs</em> (czyli mogą dotyczyć tylko
plików w katalogu <code>/usr/src/minix/fs/mfs</code>).</li>
<li>Podczas działania zmodyfikowany serwer nie może wypisywać żadnych dodatkowych
informacji na konsolę ani do rejestru zdarzeń (ang. <em>log</em>).</li>
<li>Można założyć, że w testowanych przypadkach użytkownik będzie miał
wystarczające uprawnienia do wykonania wszystkich operacji.</li>
<li>Można założyć, że w testowanych przypadkach w systemie plików będą tylko
zwykłe pliki (nie łącza, nie pseudourządzenia itp.) i katalogi.</li>
<li>Rozwiązanie nie musi być optymalne pod względem prędkości działania.
Akceptowane będą rozwiązania, które działają bez zauważalnej dla użytkownika
zwłoki.</li>
<li>Można założyć, że na MINIX-e będzie zawsze ustawiona prawidłowa data i
godzina, a rozwiązanie nie musi działać poprawnie przed 2021 i po 2037 roku oraz
nie musi obsługiwać poprawnie dysków, na których znajdują się pliki stworzone,
zmodyfikowane lub odczytane poza tym okresem.</li>
</ol>

<h2>Wskazówki</h2>

<ol>
<li><p>Aby skompilować i zainstalować zmodyfikowany serwer <em>mfs</em>, należy wykonać
<code>make; make install</code> w katalogu <code>/usr/src/minix/fs/mfs</code>. Takimi poleceniami
będzie budowane i instalowane oddane rozwiązanie.</p></li>
<li><p>Każde zamontowane położenie (ich listę wyświetli polecenie <code>mount</code>)
obsługiwane jest przez nową instancję serwera <em>mfs</em>. Położenia zamontowane przed
instalacją nowego serwera będą obsługiwane nadal przez jego starą wersję, więc
aby przetestować na nich zmodyfikowany serwer, należy je odmontować i zamontować
ponownie lub zrestartować system.</p></li>
<li><p>Aby zmodyfikowany serwer obsługiwał też korzeń systemu plików (<code>/</code>), należy
wykonać dodatkowe kroki, ale radzimy nie testować na nim (i nie wymagamy tego)
zmodyfikowanego serwera <em>mfs</em>.</p></li>
<li><p>Do MINIX-a uruchomionego pod <em>QEMU</em> można dołączać dodatkowe dyski twarde
(i na nich testować swoje modyfikacje). Aby z tego skorzystać, należy:</p>

<p>A. Na komputerze-gospodarzu stworzyć plik będący nowym dyskiem, np.:
<code>qemu-img create -f raw extra.img 1M</code>.</p>

<p>B. Podłączyć ten dysk do maszyny wirtualnej, dodając do parametrów, z jakimi
uruchamiane jest <em>QEMU</em>, parametry
<code>-drive file=extra.img,format=raw,index=1,media=disk</code>, gdzie parametr <code>index</code>
określa numer kolejny dysku (0 to główny dysk – obraz naszej maszyny).</p>

<p>C. Za pierwszym razem stworzyć na nowym dysku system plików mfs:
<code>/dev/c0d&lt;numer kolejny dodanego dysku&gt;</code>, np. <code>/sbin/mkfs.mfs /dev/c0d1</code>.</p>

<p>D. Stworzyć pusty katalog (np. <code>mkdir /root/nowy</code>) i zamontować do niego
podłączony dysk: <code>mount /dev/c0d1 /root/nowy</code>.</p>

<p>E. Wszystkie operacje wewnątrz tego katalogu będą realizowane na
zamontowanym w tym położeniu dysku.</p>

<p>F. Aby odmontować dysk, należy użyć polecenia <code>umount /root/nowy</code>.</p></li>
<li><p>Tablica z funkcjami obsługiwanymi przez serwer <em>mfs</em> znajduje się w pliku <code>table.c</code>.</p></li>
<li><p>W MINIX-ie małe ilości informacji przekazuje się między procesami poprzez
wiadomości (zob. Laboratorium 7), natomiast większe porcje danych poprzez
niskopoziomową pamięć dzieloną – tzw. granty (zob. punkt 4.2 w Laboratorium 7).</p></li>
<li><p>Szukając miejsca do przechowywania na dysku dodatkowych informacji o zapisanych
na nim plikach, można skorzystać z wymagania poprawnego działania systemu plików
tylko od 2021 do 2037 roku.</p></li>
<li><p>Implementacja serwera <em>mfs</em> nie jest omawiana na zajęciach, ponieważ jednym z
celów tego zadania jest samodzielne przeanalizowanie odpowiednich fragmentów
kodu źródłowego MINIX-a. Rozwiązując to zadanie, należy więcej kodu przeczytać,
niż samodzielnie napisać lub zmodyfikować.</p></li>
</ol>

<h2>Rozwiązanie</h2>

<p>Poniżej przyjmujemy, że <em>ab123456</em> oznacza identyfikator studenta rozwiązującego
zadanie. Należy przygotować łatkę (ang. <em>patch</em>) ze zmianami. Plik o nazwie
<code>ab123456.patch</code> uzyskujemy za pomocą polecenia <code>diff -rupNEZbB</code>, tak jak w
zadaniu 3. Łatka będzie aplikowana przez umieszczenie jej w katalogu <code>/</code> nowej
kopii MINIX-a i wykonanie polecenia <code>patch -p1 &lt; ab123456.patch</code>. Należy zadbać,
aby łatka zawierała tylko niezbędne różnice. Na Moodle należy umieścić tylko
łatkę ze zmianami.</p>

<h2>Ocenianie</h2>

<p>Oceniana będą zarówno poprawność, jak i styl rozwiązania. Podstawą do oceny
rozwiązania będą testy automatyczne sprawdzające poprawność implementacji oraz
przejrzenie kodu przez sprawdzającego. Za poprawną i w dobrym stylu
implementację funkcjonalności opisanych w punktach (A), (B) i (C) rozwiązanie
otrzyma odpowiednio: 2 pkt., 1 pkt i 2 pkt. Rozwiązanie, w którym łatka nie
nakłada się poprawnie, które nie kompiluje się lub powoduje <em>kernel panic</em>
podczas uruchamiania, otrzyma 0 pkt.</p>
    
</div></div>
