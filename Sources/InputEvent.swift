import Glibc
import CLinuxInput
import Dispatch

let keyEvent = UInt16(EV_KEY)

typealias KeyEventHandler = ((UInt16) -> Void)

class InputEventCenter {
	var keyPressed:  KeyEventHandler?
	var keyReleased: KeyEventHandler?
	var keyRepeated: KeyEventHandler?
	
	var couldNotRead: ((_ reason: String) -> Void)?
	
	init(devicePath: String) throws {
		let device = open(devicePath, O_RDONLY)
		guard device != -1 else {
			throw KeyboardError.CannotOpen(
				fileDescriptor: devicePath,
				reason: errorString()
			)
		}
		
		DispatchQueue.global().async {
			var event = input_event()
			while true {
				guard read(device, &event, MemoryLayout<input_event>.size) != -1 else {
					self.couldNotRead?(errorString())
					break
				}
				
				if event.type == keyEvent {
					let handler: KeyEventHandler?
					switch event.value {
					case 0:
						handler = self.keyReleased
					case 1:
						handler = self.keyPressed
					case 2:
						handler = self.keyRepeated
					default:
						handler = nil
					}
					handler?(event.code)
				}
			}
		}
	}
}