#LIB_ANTLR := lib/antlr-4.7.2-complete.jar
ANTLR_SCRIPT := Micro.g4

all: group compiler

group:
	@echo "Zhifei Chen  Yuhao Hu"
compiler:
	rm -rf build
	mkdir build
	java -cp $(CLASSPATH) org.antlr.v4.Tool -o build $(ANTLR_SCRIPT)
	rm -rf classes
	mkdir classes
	javac -cp $(CLASSPATH) -d classes src/*.java build/*.java
clean:
	rm -rf classes build

.PHONY: all group compiler clean
