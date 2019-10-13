# rp-radio
An in-game radio which makes use of the TokoVOIP radio API for FiveM

### Exports
Getters

| Export           | Description                                         | Return type |
| ---------------- | --------------------------------------------------- | ----------- |
| IsRadioOpen      | Check if player is holding radio                    | bool        |
| IsRadioOn        | Check if radio is switched on                       | bool        |
| IsRadioAvailable | Check if player has a radio                         | bool        |
| IsRadioEnabled   | Check if radio is enabled                           | bool        |
| CanRadioBeUsed   | Check if radio can be used                          | bool        |
| IsEmergency      | Check if player has access to emergency frequencies | bool        |

Setters
 
| Export           | Description                                         | Parameter(s) |
| ---------------- | --------------------------------------------------- | ------------ |
| SetRadioEnabled  | Set if the radio is enabled or not                  | bool         |
| SetRadio         | Set if player has a radio or not                    | bool         |
| SetEmergency     | Set if player has access to emergency frequencies   | bool         |

### Commands

| Command    | Description              |
| ---------- | ------------------------ |
| /radio     | Open/close the radio     |
| /frequency | Choose radio frequency   |

### Events

| Event        | Description                      | Paramters(s)           |
| ------------ | -------------------------------- | ---------------------- |
| Radio.Toggle | Opens/close the radio            | none                   |
| Radio.Set    | Set if player has a radio or not | bool                   |
