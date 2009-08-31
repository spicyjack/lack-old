    #include <stdio.h>
    #include <unistd.h>
    #include <sys/types.h>

  int main(int argc, char *argv[])
  {
/* pid_t pid = getpid(); */
    printf("Hello world!\n");
    printf("current PID is: %d\n" , getpid() ); 
    sleep(9999999);
    return 0;
  }


