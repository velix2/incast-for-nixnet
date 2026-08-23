all: client server
	echo "hi"

all-silent: client-silent server-silent
	echo "making silent"

client: clean
	g++ -g client/client.cc -o client/a.out

server: clean
	g++ -g server/server.cc -o server/a.out

client-silent: clean
	g++ -g client/client-silent.cc -o client/a.out

server-silent: clean
	g++ -g server/server-silent.cc -o server/a.out

clean:
	rm -f client/a.out
	rm -f server/a.out 

