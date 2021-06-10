Systemy operacyjne, zadanie 4
  

<div class="container">

<h2>Treść</h2>

<p>Celem zadania jest zaimplementowanie strategii szeregowania <q>lowest unique bid</q>
oraz dodanie wywołania systemowego, które umożliwi procesom wybór
tej strategii.</p>

<p>Każdy proces szeregowany tym algorytmem składa pewną ofertę (ang. <em>bid</em>),
będącą liczbą całkowitą nieujemną, która powinna być przechowywana przez system operacyjny.
Do wykonania zostaje wybrany proces, którego oferta jest najmniejszą liczbą niewskazaną przez
żaden inny proces.</p>

<p>Wszystkie procesy szeregowane zgodnie z algorytmem <q>lowest unique bid</q> mają ten sam
ustalony priorytet <code>AUCTION_Q</code>, co oznacza, że znajdują się w tej samej
kolejce procesów gotowych do wykonania. W obrębie tej kolejki wybieramy proces do
wykonania zgodnie z zasadami aukcji <q>lowest unique bid</q>, tj. wybieramy proces, który
złożył najmniejszą unikalną ofertę. Jeśli takiego procesu nie ma, to wybieramy dowolny proces,
który złożył jedną z najwyższych ofert. Dla przykładu, jeśli w kolejce <code>AUCTION_Q</code>
mamy procesy <code>p1</code>, <code>p2</code>, <code>p3</code>, <code>p4</code>, <code>p5</code>
i <code>p6</code>, które złożyły oferty odpowiednio 20, 40,
50, 60, 20 i 50, to najpierw wykona się
proces <code>p2</code> (jako że 40 to najmniejsza spośród unikalnych ofert), potem <code>p4</code>, następnie w dowolnej kolejności <code>p3</code>
i <code>p6</code>, a na koniec, w dowolnej kolejności <code>p1</code> i <code>p5</code>.
Należy zapewnić prawidłowe umieszczenie procesu w kolejce w czasie szeregowania.</p>

<p>Podczas działania procesy szeregowane zgodnie z nowym algorytmem nie zmieniają
swojego priorytetu (kolejki) w odróżnieniu od zwykłych procesów szeregowanych domyślnie.
Należy zadbać o to, aby zwykłym procesom nie był przydzielany priorytet <code>AUCTION_Q</code>. </p>

<h3>Implementacja</h3>

<p>Implementacja powinna zawierać:</p>

<ul>
  <li>Definicję stałej <code>AUCTION_Q = 8</code> określającej priorytet procesów
    szeregowanych algorytmem <q>lowest unique bid</q>.</li>

  <li>Nową funkcję systemową: <code>int setbid(int bid)</code>.

  Jeśli wartość parametru jest dodatnia, to szeregowanie procesu zostanie
  zmienione na algorytm <q>lowest unique bid</q> z ofertą równą <code>bid</code>.
  Wartość 0 oznacza, że proces rezygnuje z szeregowania <q>lowest unique bid</q> i
  wraca do szeregowania domyślnego.<br>

  Funkcja powinna przekazywać jako wynik 0, jeśli metoda szeregowania
  została zmieniona pomyślnie, a −1 w przeciwnym przypadku. Jeśli wartość
  parametru nie jest prawidłowa (ujemna lub większa niż
  <code>MAX_BID = 100</code>), to <code>errno</code> przyjmuje wartość
  <code>EINVAL</code>. Jeśli proces, który chce zmienić metodę szeregowania
  na <q>lowest unique bid</q>, jest już szeregowany zgodnie z tym algorytmem, to
  <code>errno</code> przyjmuje wartość <code>EPERM</code>. Podobnie powinno się
  stać, gdy proces, który chce zrezygnować z szeregowania <q>lowest unique bid</q>,
  wcale nie jest nim szeregowany.</li>

  <li>Bezpośrednio za nagłówkiem każdej funkcji,
    która została dodana lub zmieniona, należy dodać komentarz
    <code>/* so_2021 */</code>.</li>
</ul>

<p>Dopuszczamy zmiany w katalogach:</p>

<ul>
   <li><code>/usr/src/minix/servers/sched</code>,</li>
   <li><code>/usr/src/minix/servers/pm</code>,</li>
   <li><code>/usr/src/minix/kernel</code>,</li>
   <li><code>/usr/src/lib/libc/misc</code>,</li>
   <li><code>/usr/src/minix/lib/libsys</code>.</li>
</ul>

<p>oraz w plikach nagłówkowych:</p>

<ul>
   <li><code>/usr/src/minix/include/minix/com.h</code>
   który będzie kopiowany do <code>/usr/include/minix/com.h</code>,</li>
   <li><code>/usr/src/minix/include/minix/callnr.h</code>,
   który będzie kopiowany do <code>/usr/include/minix/callnr.h</code>,</li>
   <li><code>/usr/src/include/unistd.h</code>,
   który będzie kopiowany do <code>/usr/include/unistd.h</code>,</li>
   <li><code>/usr/src/minix/include/minix/syslib.h</code>,
   który będzie kopiowany do <code>/usr/include/minix/syslib.h</code>,</li>
   <li><code>/usr/src/minix/include/minix/ipc.h</code>,
   który będzie kopiowany do <code>/usr/include/minix/ipc.h</code>,</li>
   <li><code>/usr/src/minix/include/minix/config.h</code>,
   który  będzie kopiowany do <code>/usr/include/minix/config.h</code>.
</li></ul>

<h3>Wskazówki</h3>

<ul>
  <li>Do zmieniania metody szeregowania można dodać nową funkcję systemową
      mikrojądra. Warto w tym przypadku wzorować się na przykład na funkcji
      <code>do_schedule()</code>. Można też próbować zmodyfikować tę funkcję.</li>

  <li>Przypominamy, że za wstawianie do kolejki procesów gotowych
    odpowiedzialne jest mikrojądro
    (<code>/usr/src/minix/kernel/proc.c</code>). Natomiast o wartości
    priorytetu decyduje serwer <code>sched</code>, który powinien dbać o to, aby
    zwykłym procesom nie przydzielić priorytetu <code>AUCTION_Q</code>.</li>

  <li>Nie trzeba (i nie jest zalecane) pisanie nowego serwera szeregującego.
    Można zmodyfikować domyślny serwer <code>sched</code>.</li>

  <li>Aby nowy algorytm szeregowania zaczął działać, należy wykonać
      <code>make; make install</code> w katalogu
      <code>/usr/src/minix/servers/sched</code> oraz w innych katalogach
      zawierających zmiany. Jeśli zmiany zawiera plik <code>mproc.h</code> w kodzie serwera <code>pm</code>,
      warto też wykonać te polecenia w innych katalogach wymienionych w treści zadania 3.
      Następnie trzeba zbudować nowy obraz jądra, czyli
      wykonać <code>make do-hdboot</code> w katalogu
      <code>/usr/src/releasetools</code> i zrestartować system.
      Gdyby obraz nie chciał się załadować lub wystąpił poważny błąd
      (<code>kernel panic</code>), należy przy starcie systemu wybrać opcję 6,
      która załaduje oryginalne jądro.</li>
</ul>

<h3>Rozwiązanie</h3>

<p>Poniżej przyjmujemy, że <code>ab123456</code> oznacza identyfikator studenta
rozwiązującego zadanie. Należy przygotować łatkę (ang. <em>patch</em>) ze
zmianami w katalogu <code>/usr</code>. Plik o nazwie
<code>ab123456.patch</code> uzyskujemy za pomocą polecenia
<code>diff -rupNEZbB</code>, tak jak w zadaniu 3. Będzie on aplikowany w katalogu
<code>/</code> z opcją <code>-p1</code>.</p>

<p>Prosimy pamiętać o dodaniu odpowiednich komentarzy, ponieważ lista
  zmienionych funkcji uzyskana za pomocą polecenia
  <code>grep -r so_2021 /usr/src</code> będzie miała wpływ na ocenę zadania.
  Wystarczy, że każda funkcja pojawi się na liście tylko raz, więc nie potrzeba
  umieszczać komentarzy w plikach nagłówkowych.</p>

<p>Rozwiązanie w postaci łatki <code>ab123456.patch</code> należy
umieścić w Moodle'u. Opcjonalnie można dołączyć plik <code>README</code>.</p>

<p>Uwaga: nie przyznajemy punktów za rozwiązanie, w którym łatka nie nakłada się
poprawnie, które nie kompiluje się lub powoduje <code>kernel panic</code>
podczas uruchamiania.</p>

</div>
