default: tests.log

test:
	@../test.pl -c "../../../src/symex/symex --bfs"
	@../test.pl -c "../../../src/symex/symex --dfs"
	@../test.pl -c "../../../src/symex/symex --dfs --randomize"
	@../test.pl -c "../../../src/symex/symex --shortest-path"
	@../test.pl -c "../../../src/symex/symex --shortest-path --randomize"
	@../test.pl -c "../../../src/symex/symex --shortest-path-per-function"


tests.log: ../test.pl
	@../test.pl -c "../../../src/symex/symex --bfs"
	@../test.pl -c "../../../src/symex/symex --dfs"
	@../test.pl -c "../../../src/symex/symex --dfs --randomize"
	@../test.pl -c "../../../src/symex/symex --shortest-path"
	@../test.pl -c "../../../src/symex/symex --shortest-path --randomize"
	@../test.pl -c "../../../src/symex/symex --shortest-path-per-function"

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
