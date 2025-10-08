CMACH ?= ../mach-c/bin/cmach

# dirs
SRC_DIR := src
OUT_DIR := out
OBJ_DIR := $(OUT_DIR)/obj
LIB_DIR := $(OUT_DIR)/lib

# outputs
LIB := $(LIB_DIR)/libmachstd.a

# sources/objects
SOURCES := $(shell find $(SRC_DIR) -type f -name '*.mach')
OBJECTS := $(patsubst $(SRC_DIR)/%.mach,$(OBJ_DIR)/%.o,$(SOURCES))

.PHONY: all clean print

all: $(LIB)

$(LIB): $(OBJECTS) | $(LIB_DIR)
	@echo lib = $@
	@OBJS="$$(find $(OBJ_DIR) -type f -name '*.o' -print 2>/dev/null)"; ar rcs $@ $$OBJS

# compile each .mach to .o (no link); infer package via -M alias
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.mach | $(OBJ_DIR)
	@mkdir -p $(dir $@)
	@$(CMACH) build $< --emit-obj --no-link -I $(SRC_DIR) -M std=$(SRC_DIR) -o $@

$(OBJ_DIR):
	@mkdir -p $(OBJ_DIR)

$(LIB_DIR):
	@mkdir -p $(LIB_DIR)

clean:
	rm -rf $(OUT_DIR)

print:
	@echo cmach = $(CMACH)
	@echo lib   = $(LIB)
	@echo objs  = $(words $(OBJECTS))
