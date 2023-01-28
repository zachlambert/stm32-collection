.PHONY: build
build:
	mkdir -p build
	cmake -E chdir build cmake -DCMAKE_BUILD_TYPE=Release ..
	cmake --build build

.PHONY: clean
clean:
	rm -r build

.PHONY: install
install:
	sudo cmake --build build --target install
