default: tests.log

test:
	@../test.pl -c "../../../src/symex/symex --bfs"
	@../test.pl -c "../../../src/symex/symex --dfs"
	@../test.pl -c "../../../src/symex/symex --dfs --randomize"		

tests.log: ../test.pl
	@../test.pl -c "../../../src/symex/symex --bfs"
	@../test.pl -c "../../../src/symex/symex --dfs"
	@../test.pl -c "../../../src/symex/symex --dfs --randomize"		

show:
	@for dir in *; do \
		if [ -d "$$dir" ]; then \
			vim -o "$$dir/*.c" "$$dir/*.out"; \
		fi; \
	done;

clean:
	find -name '*.out' -execdir $(RM) '{}' \;
	find -name '*.gb' -execdir $(RM) '{}' \;
	$(RM) tests.log
