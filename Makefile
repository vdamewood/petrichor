BASE=petrboot
BINARY_SUFFIX=bin
IMAGE_SUFFIX=img
SOURCE_SUFFIX=asm

BINARY=$(BASE).$(BINARY_SUFFIX)
IMAGE=$(BASE).$(IMAGE_SUFFIX)
SOURCE=$(BASE).$(SOURCE_SUFFIX)

all: $(IMAGE)

clean:
	rm -rf $(BINARY)

distclean: clean
	rm -rf $(IMAGE)

$(IMAGE): $(BINARY)
	dd of=$(IMAGE) if=$(BINARY) bs=512        count=1
	dd of=$(IMAGE) if=/dev/zero bs=512 seek=1 count=2879

$(BINARY): $(SOURCE)
	nasm $(SOURCE) -f bin -o $(BINARY)

.PHONY: all clean distclean
