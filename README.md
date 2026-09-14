#  OpenAirScan - An example App using my package SwiftESCL

OpenAirScan is now available on the App Store:

<a target="_blank" href='https://apps.apple.com/us/app/openairscan/id1663611384'>
    <img alt='Get OpenAirScan on the App Store' src='images/AppStoreBadge.svg' height="60" />
</a>

This repo contains an entire XCode project with a small example application using the protocol. 
If you're only interested in the actual API, I've created an XCode package (also MIT), that you can check out [here](https://github.com/LeoKlaus/SwiftESCL).

## Using the example application

Either download the App from the App Store or clone and compile the project to any modern iOS device.
After opening the App, it will automatically start searching for devices supporting eSCL via Bonjour (it does need the local network permission for that) and display a list of results:

|  ![Screenshot of the main view](images/1.png)| ![View of the quick actions list](images/2.png) | ![View of the settings page for a device](images/3.png) | ![Scanning multiple pages](images/4.png) |
| - | - | - | - |