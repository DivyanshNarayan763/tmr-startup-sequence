# Startup Controller

A Verilog implementation of an event-driven startup controller for a BAJA SAE electric vehicle.

## Features

- Startup sequence FSM
- Drive mode selection FSM
- Top-level startup controller
- Verilog testbench for functional verification

## Project Structure

```
src/    - Verilog source files
tb/     - Testbenches
docs/   - Documentation and diagrams
```

## Status

The design utilises two FSMs to manage mode control and startup sequence. It also accounts for external BOOST override aswell as IMD fault assertion.

## License

MIT License
