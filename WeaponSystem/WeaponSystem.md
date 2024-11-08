# Weapon System

## Weapon 

### MetaData

#### Types 

Major Types:

| type    | value | short |
| ------- | ----- | ----- |
| Utility | 0     | U     |
| Cannon  | 1     | C     |
| Bomb    | 2     | B     |
| Misslie | 3     | M     |


Subtypes:

- Utility

| subtype   | value | short |
| --------- | ----- | ----- |
| Fuel Tank | 0     | F     |

- Cannon

| subtype            | value | short |
| ------------------ | ----- | ----- |
| Single-shot Cannon | 0     | S     |
| Auto Cannon        | 1     | A     |

- Bomb 

| subtype       | value | short |
| ------------- | ----- | ----- |
| Unguided bomb | 0     | U     |
| Glide Bomb    | 1     | G     |

- Missile 

| subtype            | value | short |
| ------------------ | ----- | ----- |
| Air to Air         | 0     | AA    |
| Air to Surface     | 1     | AS    |
| Surface to Air     | 2     | SA    |
| Surface to Surface | 3     | SS    |

#### Guide method 

| method       | index |
| ------------ | ----- |
| hud lock     | 0     |
| radar select | 1     |
| map select   | 2     |
| EOTS lock    | 3     |

#### Format 

| field        | bits |
| ------------ | ---- |
| id           | 7    |
| range        | 8    |
| guide method | 4    |
| sub type     | 2    |
| major type   | 2    |