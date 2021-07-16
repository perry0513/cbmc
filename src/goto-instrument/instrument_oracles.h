/*******************************************************************\

Module: Instrument oracles

Author: Elizabeth Polgreen

Date: July 2021

\*******************************************************************/

/// \file
/// instrument oracles

#ifndef CPROVER_GOTO_INSTRUMENT_INSTRUMENT_ORACLE_H
#define CPROVER_GOTO_INSTRUMENT_INSTRUMENT_ORACLE_H

#include <list>
#include <string>

#include <util/irep.h>

class goto_modelt;
class message_handlert;

void instrument_oracle_function(
  goto_modelt &,
  const irep_idt &identifier,
  message_handlert &);

void instrument_oracle_functions(
  goto_modelt &,
  const std::list<std::string> &names,
  message_handlert &);

#endif // CPROVER_GOTO_INSTRUMENT_INSTRUMENT_ORACLE_H
