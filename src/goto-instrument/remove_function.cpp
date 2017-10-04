/*******************************************************************\

Module: Remove function definition

Author: Michael Tautschnig

Date: April 2017

\*******************************************************************/

/// \file
/// Remove function definition

#include "remove_function.h"

#include <util/message.h>

#include "function_modifies.h"

#include <goto-programs/goto_model.h>

// removes all except relevant functions for xsa227. This is a bodge.
void remove_all_except(goto_modelt &goto_model, message_handlert &message_handler)
{
  std::vector<std::string> functions_to_keep;
  functions_to_keep.push_back("my_init");
  functions_to_keep.push_back("__CPROVER__start");
  functions_to_keep.push_back("__CPROVER_initialize");
  functions_to_keep.push_back("do_grant_table_op");
  functions_to_keep.push_back("gnttab_map_grant_ref");
  functions_to_keep.push_back("__gnttab_map_grant_ref");
  functions_to_keep.push_back("create_grant_host_mapping");
  functions_to_keep.push_back("create_grant_pte_mapping");

  forall_goto_functions(f_it, goto_model.goto_functions)
  {
    bool keep=false;
    for(const auto &n : functions_to_keep)
      if(f_it->first==n)
        keep=true;

    if(!keep)
      remove_function(goto_model, f_it->first, message_handler);
  }
}

/// Remove the body of function "identifier" such that an analysis will treat it
/// as a side-effect free function with non-deterministic return value.
/// \par parameters: symbol_table  Input symbol table to be modified
/// goto_model  Input program to be modified
/// identifier  Function to be removed
/// message_handler  Error/status output
void remove_function(
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
  else if(entry->second.is_inlined())
  {
    message.warning() << "Function " << identifier << " is inlined, "
                      << "instantiations will not be removed"
                      << messaget::eom;
  }

  if(entry->second.body_available())
  {
    message.status() << "Removing body of " << identifier
                     << messaget::eom;
    entry->second.clear();
    goto_model.symbol_table.get_writeable_ref(identifier).value.make_nil();
  }
}

/// Remove the body of all functions listed in "names" such that an analysis
/// will treat it as a side-effect free function with non-deterministic return
/// value.
/// \par parameters: symbol_table  Input symbol table to be modified
/// goto_model  Input program to be modified
/// names  List of functions to be removed
/// message_handler  Error/status output
void remove_functions(
  goto_modelt &goto_model,
  const std::list<std::string> &names,
  message_handlert &message_handler)
{
  for(const auto &f : names)
    remove_function(goto_model, f, message_handler);
}

