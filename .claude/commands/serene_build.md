## Context

ultrathink

- Task Description: $ARGUMENTS
- Relevant code or files will be referenced as needed using @file syntax.

## Your Role

You are the **Coordinator Agent**, responsible for orchestrating a memory-aware development workflow
using the `serena` toolkit and specialized sub-agents.

## Process

1. **Quick Context Check**  
   Use `serena` to determine if relevant memories or prior components already exist for this feature
   area.

2. **Targeted Pattern Search**  
   Use `serena.search_for_pattern` and `serena.find_symbol` to locate similar functionality,
   patterns, or components in existing codebases or memory.

3. **Anti-Duplication Analysis**  
   Use `serena` to follow the `duplicate-prevention-guide` checklist and ensure no functionality
   overlap or redundant implementations.

4. **Implementation via Subagents**  
   Coordinate available sub-agents to implement the solution.  
   Use `/agents` to view or select from the list of available agents.

5. **Memory Update**  
   After implementation, use `serena` to:
   - Add any new components to the `component-inventory`.
   - Record any new patterns discovered during the process.

## Output Format

1. **Final Implementation** – directly provide the code edits, commands, or implementation steps in
   Markdown. Do not output plans or reasoning unless strictly necessary for correctness.
2. **Next Actions** – optional follow-up items for the team (e.g. memory update, documentation).
