<div role="main"><span id="maincontent"></span><h2>Zadanie 2</h2><div id="intro" class="box py-3 generalbox boxaligncenter"><div class="no-overflow"><span class="filter_mathjaxloader_equation"><span class="nolink"><h2>Współbieżny Szesnastkator Noteć</h2>

<p>Zaimplementuj w asemblerze x86_64 moduł Współbieżnego Szesnastkatora Noteć
wykonującego obliczenia na 64-bitowych liczbach zapisywanych przy podstawie 16
i używającego odwrotnej notacji polskiej. Można uruchomić <code>N</code> działających
równolegle instancji Notecia, numerowanych od <code>0</code> do <code>N − 1</code>, gdzie <code>N</code> jest
parametrem kompilacji. Każda instancja Notecia wywoływana jest z języka C
w osobnym wątku za pomocą funkcji:</p>

<pre><code>uint64_t notec(uint32_t n, char const *calc);
</code></pre>

<p>Parametr <code>n</code> zawiera numer instancji Notecia. Parametr <code>calc</code> jest wskaźnikiem
na napis ASCIIZ i opisuje obliczenie, jakie ma wykonać Noteć. Obliczenie składa
się z operacji wykonywanych na stosie, który na początku jest pusty. Znaki
napisu interpretujemy następująco:</p>

<ul>
<li><p><code>0</code> do <code>9</code>, <code>A</code> do <code>F</code>, <code>a</code> do <code>f</code> – Znak jest interpretowany jako cyfra
w zapisie przy podstawie 16. Jeśli Noteć jest w trybie wpisywania liczby, to
liczba na wierzchołku stosu jest przesuwana o jedną pozycję w lewo
i uzupełniania na najmniej znaczącej pozycji podaną cyfrą. Jeśli Noteć nie jest
w trybie wpisywania liczby, to na wierzchołek stosu jest wstawiana wartość
podanej cyfry. Noteć przechodzi w tryb wpisywania liczby po wczytaniu jednego ze
znaków z tej grupy, a wychodzi z trybu wpisywania liczby po wczytaniu dowolnego
znaku nie należącego do tej grupy.</p></li>
<li><p><code>=</code> – Wyjdź z trybu wpisywania liczby.</p></li>
<li><p><code>+</code> – Zdejmij dwie wartości ze stosu, oblicz ich sumę i wstaw wynik na stos.</p></li>
<li><p><code>*</code> – Zdejmij dwie wartości ze stosu, oblicz ich iloczyn i wstaw wynik na stos.</p></li>
<li><p><code>-</code> – Zaneguj arytmetycznie wartość na wierzchołku stosu.</p></li>
<li><p><code>&amp;</code> – Zdejmij dwie wartości ze stosu, wykonaj na nich operację <code>AND</code> i wstaw
    wynik na stos.</p></li>
<li><p><code>|</code> – Zdejmij dwie wartości ze stosu, wykonaj na nich operację <code>OR</code> i wstaw
    wynik na stos.</p></li>
<li><p><code>^</code> – Zdejmij dwie wartości ze stosu, wykonaj na nich operację <code>XOR</code> i wstaw
    wynik na stos.</p></li>
<li><p><code>~</code> – Zaneguj bitowo wartość na wierzchołku stosu.</p></li>
<li><p><code>Z</code> – Usuń wartość z wierzchołka stosu.</p></li>
<li><p><code>Y</code> – Wstaw na stos wartość z wierzchołka stosu, czyli zduplikuj wartość na
    wierzchu stosu.</p></li>
<li><p><code>X</code> – Zamień miejscami dwie wartości na wierzchu stosu.</p></li>
<li><p><code>N</code> – Wstaw na stos liczbę Noteci.</p></li>
<li><p><code>n</code> – Wstaw na stos numer instancji tego Notecia.</p></li>
<li><p><code>g</code> – Wywołaj (zaimplementowaną gdzieś indziej w języku C lub Asemblerze) funkcję:</p>

<pre><code>int64_t debug(uint32_t n, uint64_t *stack_pointer);
</code></pre>

<p>Parametr <code>n</code> zawiera numer instancji Notecia wywołującego tę funkcję.
Parametr <code>stack_pointer</code> wskazuje na wierzchołek stosu Notecia.
Funkcja <code>debug</code> może zmodyfikować stos. Wartość zwrócona przez tę funkcję
oznacza, o ile pozycji należy przesunąć wierzchołek stosu po jej wykonaniu.</p></li>
<li><p><code>W</code> – Zdejmij wartość ze stosu, potraktuj ją jako numer instancji Notecia <code>m</code>.
Czekaj na operację <code>W</code> Notecia <code>m</code> ze zdjętym ze stosu numerem instancji
Notecia <code>n</code> i zamień wartości na wierzchołkach stosów Noteci <code>m</code> i <code>n</code>.</p></li>
</ul>

<p>Po zakończeniu przez Notecia wykonywania obliczenia jego wynikiem, czyli
wynikiem funkcji <code>notec</code>, jest wartość z wierzchołka stosu. Wszystkie operacje
wykonywane są na liczbach 64-bitowych modulo <code>2^64</code>. Zakładamy, że obliczenie
jest poprawne, tzn. zawiera tylko opisane wyżej znaki, kończy się zerowym
bajtem, nie próbuje sięgać po wartość z pustego stosu i nie doprowadza do
zakleszczenia. Zachowanie Notecia dla niepoprawnego obliczenia jest
niezdefiniowane.</p>

<p>Sformułowania „zdejmij dwie wartości ze stosu”, „wstaw wynik na stos” itp.
opisują semantykę operacji, a nie konieczność wykonania akurat takich operacji
na stosie.</p>

<h2>Przykład użycia</h2>

<p>Przykład użycia umieszczony jest w załączonym poniżej pliku <code>example.c</code>.</p>

<h2>Oddawanie rozwiązania i kompilowanie</h2>

<p>Jako rozwiązanie należy wstawić w Moodle plik o nazwie <code>notec.asm</code>.
Rozwiązanie będzie asemblowane na maszynie <code>students.mimuw.edu.pl</code> poleceniem:</p>

<pre><code>nasm -DN=$N -f elf64 -w+all -w+error -o notec.o notec.asm
</code></pre>

<p>Przykład kompiluje się i linkuje poleceniami:</p>

<pre><code>gcc -DN=$N -c -Wall -Wextra -O2 -std=c11 -o example.o example.c
gcc notec.o example.o -lpthread -o example
</code></pre>

<p>W powyższych poleceniach zmienna <code>$N</code> określa wartość parametru <code>N</code>.</p>

<h2>Pozostałe wymagania</h2>

<p>Jako stosu, którego do opisanych wyżej obliczeń używa Noteć, należy użyć
sprzętowego stosu procesora.
Nie należy zakładać żadnych górnych ograniczeń na wartość <code>N</code> i rozmiar stosu,
innych niż wynikające z architektury procesora i dostępnej pamięci.
Nie wolno korzystać z żadnych bibliotek.
Synchronizację wątków należy zaimplementować za pomocą jakiegoś wariantu
wirującej blokady.
Uwaga: można to zrobić bez konieczności blokowania szyny pamięci za pomocą <code>lock</code>.</p>

<p>Zadanie nie wymaga napisania dużego kodu. Kod maszynowy w pliku <code>notec.asm</code> nie
powinien zajmować więcej niż kilkaset bajtów. Jednak rozwiązanie powinno być
przemyślane i dobrze przetestowane. Nie udostępniamy naszych testów, więc
przetestowanie rozwiązania jest częścią zadania, choć nie wymagamy pokazywania
tych testów. W szczególności na potrzeby testowania należy zaimplementować
własną funkcję <code>debug</code>, ale nie należy jej implementacji dołączać do
rozwiązania.</p>

<p>Rozwiązanie zostanie poddane testom automatycznym. Będziemy sprawdzać poprawność
wykonywania obliczenia. Dokładnie będziemy też sprawdzać zgodność rozwiązania
z wymaganiami ABI, czyli prawidłowość użycia rejestrów i stosu procesora.
Oceniane będą poprawność i jakość tekstu źródłowego, w tym komentarzy, rozmiar
kodu maszynowego, zajętość pamięci oraz spełnienie formalnych wymagań podanych
w treści zadania, np. poprawność nazwy pliku.
Kod nieasemblujący się otrzyma 0 punktów.
Wystawienie oceny może też być uzależnione od osobistego wyjaśnienia szczegółów
działania programu prowadzącemu zajęcia.</p>

</span></span></div>
