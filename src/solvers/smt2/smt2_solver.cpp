/*******************************************************************\

Module: SMT2 Solver that uses boolbv and the default SAT solver

Author: Daniel Kroening, kroening@kroening.com

\*******************************************************************/

#include <fstream>
#include <iostream>

#include "smt2_parser.h"

#include <util/namespace.h>
#include <util/symbol_table.h>
#include <util/cout_message.h>
#include <solvers/sat/satcheck.h>
#include <solvers/flattening/boolbv.h>

class smt2_solvert:public smt2_parsert
{
public:
  smt2_solvert(
    std::ifstream &_in,
    decision_proceduret &_solver):
    smt2_parsert(_in),
    solver(_solver)
  {
  }

protected:
  decision_proceduret &solver;

  void command(const std::string &) override;
};

void smt2_solvert::command(const std::string &c)
{
  if(c=="assert")
  {
    exprt e=expression();
    solver.set_to_true(e);
  }
  else if(c=="check-sat")
  {
    switch(solver())
    {
    case decision_proceduret::resultt::D_SATISFIABLE:
      std::cout << "(sat)\n";
      break;

    case decision_proceduret::resultt::D_UNSATISFIABLE:
      std::cout << "(unsat)\n";
      break;

    case decision_proceduret::resultt::D_ERROR:
      std::cout << "(error)\n";
    }
  }
  else
    smt2_parsert::command(c);
}

int main(int argc, const char *argv[])
{
  if(argc!=2)
    return 1;

  std::ifstream in(argv[1]);
  if(!in)
  {
    std::cerr << "failed to open " << argv[1] << '\n';
    return 1;
  }

  symbol_tablet symbol_table;
  namespacet ns(symbol_table);

  console_message_handlert message_handler;
  messaget message(message_handler);

  // this is our default verbosity
  message_handler.set_verbosity(messaget::M_STATISTICS);

  satcheckt satcheck;
  boolbvt boolbv(ns, satcheck);
  satcheck.set_message_handler(message_handler);
  boolbv.set_message_handler(message_handler);

  smt2_solvert smt2_solver(in, boolbv);
  smt2_solver.set_message_handler(message_handler);

  smt2_solver.parse();

  if(!smt2_solver)
    return 20;
  else
    return 0;
}
