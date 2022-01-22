package c

/*
extern void putchar(char);
extern char getchar();
extern int strlen(char*);
*/
import "C"

func putchars(c []byte) {
	for _, ch := range c {
		C.putchar(ch)
	}
}

//export puts
func cputs(s *C.char) {
	putchars([]byte(C.GoStringN(s, C.strlen(s))))
}

func puts(x string) {
	putchars([]byte(x))
}
