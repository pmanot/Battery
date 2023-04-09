# Battery

A lightweight multi-platform framework for accessing battery info

## Features
* Get battery percentage, charging state, low power mode state
* Observe battery changes through published properties
* Multi-platform support

## Installation
Battery can be installed using Swift Package Manager. Simply add the following line to your Package.swift file: 
```
dependencies: [
    .package(url: "https://github.com/<username>/<reponame>.git", from: "1.0.0")
]
```

## Usage
To use the Unified Battery Framework, first, import the module: 

```
import Battery
```

Then, create an instance of the Battery class: 

```
let battery = Battery()
```

```
battery.$percentage.sink { percentage in
    print("Battery percentage: \(percentage)")
}

battery.$state.sink { state in
    print("Battery state: \(state)")
}

battery.$isLowPowerModeEnabled.sink { isEnabled in
    print("Low power mode enabled: \(isEnabled)")
}
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



