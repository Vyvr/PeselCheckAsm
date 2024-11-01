INCLUDE Irvine32.inc

.data 
	pesel byte 20 DUP (?)
	peselLength DWORD LENGTHOF pesel
	
	wagi byte 1, 3, 7, 9, 1, 3, 7, 9, 1, 3
	wagiLength DWORD LENGTHOF wagi
	
	suma WORD 0
	kontrolna WORD 0

	dzien BYTE 0
	miesiac BYTE 0
	rok DWORD 0

	dniMiesiaca BYTE ?
	dzienPoprawny BYTE 1

	msgPodajPesel byte "Podaj pesel: ", 0
	msgZlaDlugosc byte "Niepoprawna dlugosc numeru pesel", 0
	msgZlyZnak byte "Niepoprawny znak w peselu", 0
	msgZlaSumaKontrolna byte "Niepoprawna suma kontrolna", 0
	msgZlyDzien byte "Niepoprawny dzien", 0
	msgZlyMiesiac byte "Niepoprawny miesiac", 0
	msgZlyRok byte "Niepoprawny rok", 0
	msgDataUrodzenia byte "data urodzenia: ", 0

	buffer BYTE 30 DUP(0)

.code
main PROC
	mov edx, offset msgPodajPesel
	call writestring
	mov edx, offset pesel
	mov ecx, 19
	call readstring ;zapisuje wartosc do eax
	cmp eax, 11
	jne zladlugosc

	mov ecx, 11
	mov esi, offset pesel

	et1:
		cmp byte ptr [esi], '0' ; ptr robi konwersje [esi] na byte (wie, ze ma odczytac pojedynczy bajt z adresu)
		jl zlyznak
		cmp byte ptr [esi], '9'
		jg zlyznak
		inc esi
		loop et1
		
	mov esi, offset pesel
	mov edi, offset wagi

	mov ecx, wagiLength
	
	sumaKontrolna:
		mov	al, [esi]
		cmp al, 0
		je koniec
		sub al, '0'

		; Mno�enie cyfry pesel przez wag�, wynik w AX
		mov bl, [edi]
		mul bl
		
		; Reszta z dzielenia przez 10
		mov dx, 0
		mov bx, 10

		div bx

		mov ax, dx

		add suma, ax

		; Inkrementacja licznik�w
		inc esi
		inc edi
		loop sumaKontrolna

		mov ax, suma

		; Reszta z dzielenia przez 10
		mov dx, 0
		mov bx, 10

		div bx

		mov ax, dx

		cmp ax, 0
		jne is_not_10

		mov ax, 10

	is_not_10:
		mov bx, 10

		sub bx, ax
		mov kontrolna, bx
		
		mov esi, offset pesel
		mov ecx, 0
		add ecx, wagiLength
		add ecx, 1

	znajdzOstatniIndeksPeselu:
		mov al, [esi]
		cmp ecx, 1
		je sprawdzSume
		inc esi
		loop znajdzOstatniIndeksPeselu

	sprawdzSume:
		sub ax, '0'
		cmp ax, kontrolna
		jne zlaSumaKontrolna

	sprawdzRok:
		lea esi, pesel

		; Wyodr�bnienie roku
		movzx eax, byte ptr [esi] ; Pierwsza cyfra roku
		sub eax, '0'
		imul eax, 10

		movzx ebx,byte ptr [esi + 1] ; Druga cyfra roku
		sub ebx, '0'
		add eax, ebx ; Rok
		
		; Sprawdzanie stulecia
		movzx ecx, byte ptr [esi + 2]
		cmp ecx, '2'
		jb not_2000

		cmp ecx, '3'
		ja zlyRok

		add eax, 2000
		mov rok, eax
		jmp sprawdzMiesiac
		
		not_2000:
		 add eax, 1900
		 mov rok, eax

	sprawdzMiesiac:
		lea esi, pesel + 2

		; Wyodr�bnienie miesi�ca
		movzx eax, byte ptr [esi] ; Wczytaj pierwsz� cyfr� miesi�ca
		sub eax, '0'
		imul eax, 10
    
		movzx ebx, byte ptr [esi + 1] ; Wczytaj drug� cyfr� miesi�ca
		sub ebx, '0'             
		add eax, ebx             

		mov miesiac, al

		cmp miesiac, 33
		jae zlyMiesiac

		cmp miesiac, 20
		ja month_2000

		cmp miesiac, 12
		ja zlyMiesiac

		cmp miesiac, 1
		jb zlyMiesiac

		jmp sprawdzDzien

		month_2000:
			cmp miesiac, 21
			jb zlyMiesiac
			mov al, miesiac
			sub al, 20
			mov miesiac, al

	sprawdzDzien:
		lea esi, pesel + 4

		movzx eax, byte ptr [esi] ; Wczytaj pierwsz� cyfr� dnia
		sub eax, '0'
		imul eax, 10
    
		movzx ebx, byte ptr [esi + 1] ; Wczytaj drug� cyfr� dnia
		sub ebx, '0'             
		add eax, ebx 
		
		cmp al, 1
		jb zlyDzien

		cmp al, 31
		ja zlyDzien

		mov dzien, al

	sprawdzDzienDoMiesiaca:
		call SprawdzDzienDokladnie
		mov eax, 0
		mov al, dniMiesiaca
		cmp dzien, al
		ja zlyDzien

	wypiszDateUrodzenia:
		call WypiszDate	
		
	jmp koniec

	zlyDzien:
		mov edx, offset msgZlyDzien
		call writestring
		jmp koniec

	zlyMiesiac:
		mov edx, offset msgZlyMiesiac
		call writestring
		jmp koniec

	zlyRok:
		mov edx, offset msgZlyRok
		call writestring
		jmp koniec

	zlaSumaKontrolna:
		mov edx, offset msgZlaSumaKontrolna
		call writestring
		jmp koniec

	zladlugosc:
		mov edx, offset msgZlaDlugosc
		call writestring
		jmp koniec

	zlyznak:  
		mov edx, offset msgZlyZnak
		call writestring
		jmp koniec
		
	koniec:
		exit 
main endp

; Sprawdzanie dokladne dnia
SprawdzDzienDokladnie PROC
    mov al, miesiac
    mov ecx, rok
	
	; czy miesi�c to Luty
    cmp al, 2
    jne nieLuty

	 ; czy rok jest przest�pny
    mov ax, cx
    mov dx, 0
    mov bx, 4
    div bx
    cmp dx, 0
    jne niePrzestepny

    ; Sprawdzanie wyj�tkow dla lat podzielnych przez 100, kt�re nie s� przest�pne, chyba �e
    ; s� r�wnie� podzielne przez 400
    mov dx, 0
	div cx
	cmp dx, 0
    jnz przestepny          ; rok nie jest podzielny przez 100
    
    ; Rok podzielny przez 100, czy podzielny przez 400
    mov dx, 0
    mov bx, 400
    div bx
    cmp dx, 0
    jne niePrzestepny      ; Je�li reszta nie jest 0, rok nie jest przest�pny

przestepny:
    mov dniMiesiaca, 29     ; Luty ma 29 dni w roku przest�pnym
    jmp sprawdzanieDniaDone

niePrzestepny:
    mov dniMiesiaca, 28     ; Luty ma 28 dni, je�li rok nie jest przest�pny
    jmp sprawdzanieDniaDone

nieLuty:
    ; Sprawd� miesi�ce maj�ce 30 dni
    cmp al, 4
    je trzydziesciDni
    cmp al, 6
    je trzydziesciDni
    cmp al, 9
    je trzydziesciDni
    cmp al, 11
    je trzydziesciDni

    ; Reszta ma 31 dni
    mov dniMiesiaca, 31
    jmp sprawdzanieDniaDone

trzydziesciDni:
    mov dniMiesiaca, 30

sprawdzanieDniaDone:
	ret

SprawdzDzienDokladnie ENDP

; Wypisywanie daty urodzenia
WypiszDate PROC
	mov edx, offset msgDataUrodzenia
	call writestring

	mov al, dzien
	call writeint

	mov al, '.'
	call writechar

	mov al, miesiac
	call writeint

	mov al, '.'
	call writechar

	mov eax, 0
	mov eax, rok
	call writeint

	ret

WypiszDate ENDP

end main



