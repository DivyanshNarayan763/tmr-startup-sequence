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

Current implementation is event-driven using button-triggered state transitions.

A clocked implementation with synchronized inputs is planned for a future revision.

## License

MIT License