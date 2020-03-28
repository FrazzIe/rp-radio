# rp-radio
An in-game radio which makes use of the mumble-voip radio API for FiveM

#### Note
By default the radio is disabled (its meant to be used as an in-game item) to give players the radio by default in the client.lua at the top change `Radio.Has` to `true`, if you would like to make it an item look at the replies on the FiveM forum post, there is a tutorial for adding it as an ESX item.

The export that is used to give/take a players radio is `exports:["rp-radio"]:SetRadio(true/false)` or the event `Radio.Set`

### Exports
Getters

| Export           | Description                                         | Return type |
| ---------------- | --------------------------------------------------- | ----------- |
| IsRadioOpen      | Check if player is holding radio                    | bool        |
| IsRadioOn        | Check if radio is switched on                       | bool        |
| IsRadioAvailable | Check if player has a radio                         | bool        |
| IsRadioEnabled   | Check if radio is enabled                           | bool        |
| CanRadioBeUsed   | Check if radio can be used                          | bool        |

Setters
 
| Export                          | Description                                                 | Parameter(s)  |
| ------------------------------- | ----------------------------------------------------------- | ------------- |
| SetRadioEnabled                 | Set if the radio is enabled or not                          | bool          |
| SetRadio                        | Set if player has a radio or not                            | bool          |
| SetAllowRadioWhenClosed         | Allow player to broadcast when closed                       | bool          |
| AddPrivateFrequency             | Make a frequency private                                    | int           |
| RemovePrivateFrequency          | Make a private frequency public                             | int           |
| GivePlayerAccessToFrequency     | Give a player access to use a private frequency             | int           |
| RemovePlayerAccessToFrequency   | Remove a players access to use a private frequency          | int           |
| GivePlayerAccessToFrequencies   | Give a player access to use multiple private frequencies    | int, int, ... |
| RemovePlayerAccessToFrequencies | Remove a players access to use multiple private frequencies | int, int, ... |

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

### Preview

- [MP4](https://imgur.com/bAT0mls)
