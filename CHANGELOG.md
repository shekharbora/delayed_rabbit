# Changelog

## [Unreleased]

### Fixed
- Declare the exchange as `x-delayed-message`; it was previously declared as a plain topic exchange, so messages were delivered without delay.
- `JobPublisher` now uses `DelayedRabbit.configuration`.
- `JobPublisher.new` takes keyword arguments (`connection_options:`, `exchange_options:`, `queue_options:`, `connection:`, `config:`).
- Dead-lettered messages go to a separate `delayed_jobs.dlx` exchange and `delayed_jobs.dead` queue instead of looping back into the work queue.
- Custom queue/exchange `arguments` are merged with the defaults instead of replacing them.
- `JobPublisher.publish` closes its connection even when publishing fails.
- The Railtie loads `config/rabbitmq.yml` before app initializers, so the initializer can override it, and no longer fails when the file is missing.
- The rake task loads from Rails apps and defaults to a 5000ms delay.
- The install generator finds its templates and copies `rabbitmq.yml` verbatim instead of evaluating its ERB at generation time.

### Added
- `DelayedRabbit.publish`, which reuses one connection across calls.
- Configurable `exchange_name`, `queue_name`, `routing_key`, `dead_letter_exchange_name` and `dead_letter_queue_name`.
- Delay validation against the plugin's maximum (2^32 - 1 ms).

## [0.1.0]

- Initial release.
