# Custom Radar Addon

## Constants

- track target id dial name: `[CR] targetId`, 0 -> no tracking
- target id pad name: `[CR] t[1..6]id`, 0 -> radar off, -1 -> send all targets with ttl, [1..n] -> send specific target
- target pos pad name: `[CR] t[1..6][xyz]`
- target ttl pad name: `[CR] ttl`
- self id pad name: `[CR] id`

## exclude tags

- `trade`
- `resource`
- `storage`