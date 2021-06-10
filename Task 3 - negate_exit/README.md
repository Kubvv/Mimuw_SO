<div role="main"><span id="maincontent"></span><h2>Zadanie 3</h2><div id="intro" class="box py-3 generalbox boxaligncenter"><div class="no-overflow"><span class="filter_mathjaxloader_equation"><span class="nolink"><p>Zadanie polega na dodaniu wywołania systemowego <code>PM_NEGATEEXIT</code> oraz
funkcji bibliotecznej <code>int negateexit(int negate)</code>. Funkcja powinna
być zadeklarowana w pliku <code>unistd.h</code>.</p>

<h2>Negacja kodu powrotu procesu</h2>

<p>W MINIX-ie proces kończy działanie, wywołując <code>_exit(status)</code>, gdzie <code>status</code>
to kod powrotu procesu. Rodzic może odczytać kod powrotu swojego potomka,
korzystając np. z <code>wait</code>. Powłoka umieszcza kod powrotu ostatnio zakończonego
procesu w zmiennej <code>$?</code>. Chcemy umożliwić procesowi wpływanie na
wartość kodu powrotu swojego i swoich nowo tworzonych dzieci.</p>

<p>Nowa funkcja <code>int negateexit(int negate)</code>, gdy zostanie wywołana z
parametrem różnym od zera, powoduje, że gdy proces wywołujący tę
funkcję zakończy działanie z kodem zero, rodzic odczyta kod powrotu
równy jeden, a gdy zakończy działanie z kodem różnym od zera – rodzic
odczyta zero. Wywołanie tej funkcji z parametrem równym zeru przywraca
standardową obsługę kodów powrotu.</p>

<p>Wartość zwracana przez tę funkcję to informacja o zachowaniu procesu
przed wywołaniem funkcji: <code>0</code> oznacza, że kody powrotu nie były
zmieniane, a <code>1</code> – że były negowane. Jeśli wystąpi jakiś błąd, należy
zwrócić <code>-1</code> i ustawić <code>errno</code> na odpowiednią wartość.</p>

<p>Nowo tworzony proces ma dziedziczyć aktualne zachowanie rodzica,
natomiast przyszłe zmiany zachowania rodzica (wynikające z kolejnych
wywołań <code>negateexit()</code>) nie mają wpływu na potomka.</p>

<p>Jeżeli proces kończy działanie w inny sposób, niż używając systemowego
wywołania <code>PM_EXIT</code> (używanego przez funkcję <code>_exit()</code>), np. na skutek
sygnału, to jego kod powrotu nie powinien zostać zmieniony.</p>

<p>Na początku działania systemu, w szczególności dla procesu <code>init</code>,
kody powrotu <em>nie mają</em> być negowane.</p>

<p>Działanie funkcji <code>negateexit()</code> powinno polegać na użyciu nowego
wywołania systemowego <code>PM_NEGATEEXIT</code>, które należy dodać do serwera
<code>PM</code>. Do przekazania parametru należy zdefiniować własny typ
komunikatu.</p>

<h2>Format rozwiązania</h2>

<p>Poniżej przyjmujemy, że <code>ab123456</code> oznacza identyfikator studenta rozwiązującego
zadanie. Należy przygotować łatkę (ang. <em>patch</em>) ze zmianami w katalogu <code>/usr</code>.
Plik zawierający łatkę o nazwie <code>ab123456.patch</code> uzyskujemy za pomocą polecenia</p>

<pre><code>diff -rupNEZbB oryginalne-źródła/usr/ moje-rozwiązanie/usr/ &gt; ab123456.patch
</code></pre>

<p>gdzie <code>oryginalne-źródła</code> to ścieżka do niezmienionych źródeł MINIX-a, natomiast
<code>moje-rozwiązanie</code> to ścieżka do źródeł MINIX-a zawierających rozwiązanie.
Tak użyte polecenie <code>diff</code> rekurencyjnie przeskanuje pliki ze ścieżki
<code>oryginalne-źródła/usr</code>, porówna je z plikami ze ścieżki <code>moje-rozwiązanie/usr</code>
i wygeneruje plik <code>ab123456.patch</code>, który podsumowuje różnice.
Tego pliku będziemy używać, aby automatycznie nanieść zmiany na czystą kopię
MINIX-a, gdzie będą przeprowadzane testy rozwiązania. Więcej o poleceniu <code>diff</code>
można dowiedzieć się z podręcznika (<code>man diff</code>).</p>

<p>Umieszczenie łatki w katalogu <code>/</code> na czystej kopii MINIX-a i wykonanie polecenia</p>

<pre><code>patch -p1 &lt; ab123456.patch
</code></pre>

<p>powinno skutkować naniesieniem wszystkich oczekiwanych zmian wymaganych przez
rozwiązanie. Należy zadbać, aby łatka zawierała tylko niezbędne różnice.</p>

<p>Po naniesieniu łatki zostaną wykonane polecenia:</p>

<ul>
<li><code>make &amp;&amp; make install</code> w katalogach <code>/usr/src/minix/fs/procfs</code>,
<code>/usr/src/minix/servers/pm</code>,
<code>/usr/src/minix/drivers/storage/ramdisk</code>,
<code>/usr/src/minix/drivers/storage/memory</code> oraz <code>/usr/src/lib/libc</code>,</li>
<li><code>make do-hdboot</code> w katalogu <code>/usr/src/releasetools</code>,</li>
<li><code>reboot</code>.</li>
</ul>

<p>Rozwiązanie w postaci łatki <code>ab123456.patch</code> należy umieścić na Moodlu.</p>

<h2>Uwagi</h2>

<ul>
<li>Serwer PM przechowuje informacje o procesach w tablicy <code>mproc</code>
zadeklarowanej w pliku <code>mproc.h</code>.</li>
<li>Warto przeanalizować, jak PM realizuje wywołania systemowe. Więcej
informacji o działaniu tego serwera będzie na laboratorium 7.</li>
<li>Należy samodzielnie przetestować rozwiązanie. Jeden z podstawowych
scenariuszy jest następujący: uruchamiamy proces A, który włącza
negowanie kodów powrotu, a następnie uruchamia proces B. Proces B
uruchamia proces C, który kończy działanie z kodem <code>0</code>, ale z
powodu włączonego negowania proces B odbiera ten kod jako
<code>1</code>. Następnie proces A wyłącza negowanie kodów powrotu, proces B
kończy się z kodem <code>1</code>, który A odbiera jako <code>0</code>, gdyż wyłączenie
negowania w A nie ma wpływu na wcześniej uruchomione B.</li>
<li>Nie przyznajemy punktów za rozwiązanie, w którym łatka nie nakłada
się poprawnie, które nie kompiluje się lub które powoduje <em>kernel
panic</em> podczas uruchamiania systemu.</li>
</ul>
