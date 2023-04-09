# Battery

A lightweight multi-platform framework for accessing battery info

## Features
* Get battery percentage, charging state, low power mode state
* Observe battery changes through published properties
* Multi-platform support

## Installation
You can add the Battery framework to your project via Swift Package Manager. Simply go to File > Swift Packages > Add Package Dependency and enter the following URL: https://github.com/pmanot/Battery.

## Usage
To use Battery, first, import the module: 

```
import Battery
```

Then, create an instance of the Battery class: 

```
let battery = Battery()
```

```
var cancellables: [AnyCancellable] = []

battery.$percentage.sink { percentage in
    print("Battery percentage: \(percentage)")
}.store(in: &cancellables)

battery.$state.sink { state in
    print("Battery state: \(state)")
}.store(in: &cancellables)

battery.$isLowPowerModeEnabled.sink { isEnabled in
    print("Low power mode enabled: \(isEnabled)")
}.store(in: &cancellables)
```

## API
`Battery` 
The main class of the framework. Provides the following properties: 

`percentage`: The battery percentage as an integer (0-100) 
`state`: The current state of the battery (BatteryState) 
`isLowPowerModeEnabled`: A boolean indicating whether low power mode is enabled or not  

`BatteryState` 
An enum representing the state of the battery. It has the following cases:  
 
`charging`: The battery is currently charging 
`discharging`: The battery is discharging 
`chargedAndPlugged`: The battery is fully charged and plugged in 
`unknown`: The battery state is unknown 

`PowerSource` 
An enum representing the power source. It has the following cases: 

`powerAdapter`: The battery is connected to a power adapter 
`battery`: The battery is running on its own power 
`unknown`: The power source is unknown 

## License
Battery is available under the MIT license. See the LICENSE file for more info.



