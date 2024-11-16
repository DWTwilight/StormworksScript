# Weapon System

## Weapon 

### MetaData

#### Types 

Major Types:

| type                  | value | short |
| --------------------- | ----- | ----- |
| Utility               | 0     | U     |
| Cannon                | 1     | C     |
| Auto Cannon           | 2     | C     |
| Unguided Bomb         | 3     | B     |
| Guided Bomb           | 4     | B     |
| Anti Aircraft Misslie | 5     | M     |
| Anti Surface Misslie  | 6     | M     |
| Rocket                | 7     | R     |


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
| TV Guide     | 4     |

#### status

| status | value           |
| ------ | --------------- |
| 0      | require target  |
| 1      | ready           |
| 2      | lauching        |
| 3      | ready to detach |


#### Metadata Format 

number 1

| field                | bits |
| -------------------- | ---- |
| default guide method | 3    |
| guide methods        | 8    |
| type                 | 4    |
| wid                  | 8    |

number 2

| field      | bits |
| ---------- | ---- |
| reserved   | 9    |
| status     | 2    |
| ammo count | 12   |

bool
| channel | value           |
| ------- | --------------- |
| 1       | lauching        |
| 2       | ready to detach |

### Weapon Control Data

Numbers

| channel | value                                            |
| ------- | ------------------------------------------------ |
| 1       | weapon id on vehicle, 0 if no weapon is selected |
| 2       | guide method, 0-7, -1 if disabled                |
| 3       | target id                                        |
| 4       | target global pos x (For GPS Target)             |
| 5       | target global pos z (For GPS Target)             |

Bool

| channel | value   |
| ------- | ------- |
| 1       | Trigger |

### Weapon Select & Display 

#### input format 

number 
| channel | value                 |
| ------- | --------------------- |
| 2N-1    | weapon metadata num1  |
| 2N      | weapon metadata num 2 |

#### output format 

number 
| channel | value               |
| ------- | ------------------- |
| 1       | selected weapon vid |
| 2       | select guide method |

bool 
| channel | value            |
| ------- | ---------------- |
| 1-N     | lauch signal 1-N |


### Weapon IDS

| id  | name     |
| --- | -------- |
| 1   | GSH-30-1 |
| 2   | PL-10    |