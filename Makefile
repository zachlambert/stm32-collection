.PHONY: build
build:
	mkdir -p build
	cmake -E chdir build cmake -DCMAKE_BUILD_TYPE=Release -DMCU_NAME=stm32f103x8 ..
	cmake --build build

.PHONY: clean
clean:
	rm -r build

.PHONY: install
install:
	cmake --build build --target install
