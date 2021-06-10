<div role="main"><span id="maincontent"></span><h2>Zadanie 1</h2><div id="intro" class="box py-3 generalbox boxaligncenter"><div class="no-overflow"><span class="filter_mathjaxloader_equation"><span class="nolink"><h2>Diakrytynizator</h2>

<p>Zaimplementuj w asemblerze x86_64 program, który czyta ze standardowego wejścia
tekst, modyfikuje go w niżej opisany sposób, a wynik wypisuje na standardowe
wyjście. Do kodowania tekstu używamy UTF-8, patrz
<a href="https://pl.wikipedia.org/wiki/UTF-8">https://pl.wikipedia.org/wiki/UTF-8</a>.
Program nie zmienia znaków o wartościach unicode z przedziału od <code>0x00</code>
do <code>0x7F</code>. Natomiast każdy znak o wartości unicode większej od <code>0x7F</code>
przekształca na znak, którego wartość unicode wyznacza się za pomocą niżej
opisanego wielomianu.</p>

<h2>Wielomian diakrytynizujący</h2>

<p>Wielomian diakrytynizujący definiuje się przez parametry wywołania
diakrytynizatora:</p>

<pre><code>./diakrytynizator a0 a1 a2 ... an
</code></pre>

<p>jako:</p>

<pre><code>w(x) = an * x^n + ... + a2 * x^2 + a1 * x + a0
</code></pre>

<p>Współczynniki wielomianu są nieujemnymi liczbami całkowitymi podawanymi
przy podstawie dziesięć. Musi wystąpić przynajmniej parametr <code>a0</code>.</p>

<p>Obliczanie wartości wielomianu wykonuje się modulo <code>0x10FF80</code>.
W tekście znak o wartości unicode <code>x</code> zastępuje się znakiem o wartości
unicode <code>w(x - 0x80) + 0x80</code>.</p>

<h2>Zakończenie programu i obsługa błędów</h2>

<p>Program kwituje poprawne zakończenia działania, zwracając kod 0.
Po wykryciu błędu program kończy się, zwracając kod 1.</p>

<p>Program powinien sprawdzać poprawność parametrów wywołania i danych wejściowych.
Przyjmujemy, że poprawne są znaki UTF-8 o wartościach unicode od <code>0</code>
do <code>0x10FFFF</code>, kodowane na co najwyżej 4 bajtach i poprawny jest wyłącznie
najkrótszy możliwy sposób zapisu.</p>

<h2>Przykłady użycia</h2>

<p>Polecenie</p>

<pre><code>echo "Zażółć gęślą jaźń…" | ./diakrytynizator 0 1; echo $?
</code></pre>

<p>wypisuje</p>

<pre><code>Zażółć gęślą jaźń…
0
</code></pre>

<p>Polecenie</p>

<pre><code>echo "Zażółć gęślą jaźń…" | ./diakrytynizator 133; echo $?
</code></pre>

<p>wypisuje</p>

<pre><code>Zaąąąą gąąlą jaąąą
0
</code></pre>

<p>Polecenie</p>

<pre><code>echo "ŁOŚ" | ./diakrytynizator 1075041 623420 1; echo $?
</code></pre>

<p>wypisuje</p>

<pre><code>„O”
0
</code></pre>

<p>Polecenie</p>

<pre><code>echo -e "abc\n\x80" | ./diakrytynizator 7; echo $?
</code></pre>

<p>wypisuje</p>

<pre><code>abc
1
</code></pre>

<h2>Oddawanie rozwiązania</h2>

<p>Jako rozwiązanie należy wstawić w Moodle plik o nazwie <code>diakrytynizator.asm</code>.
Rozwiązanie będzie kompilowane poleceniami:</p>

<pre><code>nasm -f elf64 -w+all -w+error -o diakrytynizator.o diakrytynizator.asm
ld --fatal-warnings -o diakrytynizator diakrytynizator.o
</code></pre>

<h2>Ocenianie</h2>

<p>Oceniane będą poprawność i szybkość działania programu, zajętość pamięci
(rozmiary poszczególnych sekcji), styl kodowania, komentarze. Wystawienie oceny
może też być uzależnione od osobistego wyjaśnienia szczegółów działania programu
prowadzącemu zajęcia.</p>

<p>Tradycyjny styl programowania w asemblerze polega na rozpoczynaniu etykiet od
pierwszej kolumny, mnemoników od dziewiątej kolumny, a listy argumentów od
siedemnastej kolumny. Inny akceptowalny styl prezentowany jest w przykładach
pokazywanych na zajęciach. Kod powinien być dobrze skomentowany, co oznacza
między innymi, że każda procedura powinna być opatrzona informacją, co robi,
jak przekazywane są do niej parametry, jak przekazywany jest jej wynik, jakie
rejestry modyfikuje. To samo dotyczy makr. Komentarza wymagają także wszystkie
kluczowe lub nietrywialne linie wewnątrz procedur lub makr. W przypadku
asemblera nie jest przesadą komentowanie prawie każdej linii kodu, ale należy
jak ognia unikać komentarzy typu „zwiększenie wartości rejestru rax o 1”.</p>
</span></span></div>
