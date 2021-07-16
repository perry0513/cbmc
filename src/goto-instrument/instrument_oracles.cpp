/*******************************************************************\

Module: Instrument oracles

Author: Elizabeth Polgreen

Date: July 2021

\*******************************************************************/

/// \file
/// instrument oracles

#include "instrument_oracles.h"

#include <util/message.h>

#include <goto-programs/goto_model.h>

/// Remove the body of function "identifier" such that an analysis will treat it
/// as a side-effect free function with non-deterministic return value.
/// \par parameters: symbol_table  Input symbol table to be modified
/// goto_model  Input program to be modified
/// identifier  Function to be removed
/// message_handler  Error/status output
void instrument_oracle_function(
  goto_modelt &goto_model,
  const irep_idt &identifier,
  message_handlert &message_handler)
  {
    messaget message(message_handler);

    goto_functionst::function_mapt::iterator entry=
      goto_model.goto_functions.function_map.find(identifier);
    
    if(entry==goto_model.goto_functions.function_map.end())
    {
      message.error() << "No function " << identifier
                    << " in goto program" << messaget::eom;
      return;
    }
    else if (goto_model.symbol_table.lookup_ref(identifier).type.id()!=ID_mathematical_function)
    {
      message.error() << "Function " << identifier
                    << " is not an uninterpreted function, cannot convert to oracle function" << messaget::eom;
    
      message.status()<<"func value "<< goto_model.symbol_table.lookup_ref(identifier).value.pretty()<<messaget::eom;
      message.status()<<"func type "<< goto_model.symbol_table.lookup_ref(identifier).type.pretty()<<messaget::eom;
      // message.status()<<"entry "<< entry->second.pretty()<<messaget::eom;


    }
    else
    {
      message.status()<<"Oracle instrumenting "<< goto_model.symbol_table.lookup_ref(identifier).value.pretty()<<messaget::eom;
      
    }


  }


/// Add an oracle binary name to an uninterpreted function
/// which means the SMT solver will treat this as an oracle function
/// 
/// \par parameters: symbol_table  Input symbol table to be modified
/// goto_model  Input program to be modified
/// names  List of functions to be oracled
/// message_handler  Error/status output
void instrument_oracle_functions(
  goto_modelt &goto_model,
  const std::list<std::string> &names,
  message_handlert &message_handler)
  {
    for(const auto &f : names)
        instrument_oracle_function(goto_model, f, message_handler);
  }