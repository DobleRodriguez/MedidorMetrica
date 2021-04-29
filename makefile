CC = g++
FL = flex++
NAME = MedidorMetrica
EJEMPLO = Poema.txt
# Se utiliza el flag de ignorar advertencias porque el uso del operador / genera múltiples
# advertencias por su riesgosa naturaleza, pero en todas las ocurrencias está delimitado
FL_FLAGS = -w

all: $(NAME)
	@./$(NAME) $(EJEMPLO)

$(NAME): lex.yy.cc
	@$(CC) -o $(NAME) lex.yy.cc

lex.yy.cc: $(NAME).l
	@$(FL) $(FL_FLAGS) $(NAME).l

clean: 
	-@rm lex.yy.cc $(NAME)