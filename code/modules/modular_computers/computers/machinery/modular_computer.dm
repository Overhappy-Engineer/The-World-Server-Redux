// Modular Computer - device that runs various programs and operates with hardware
// DO NOT SPAWN THIS TYPE. Use /laptop/ or /console/ instead.
/obj/machinery/modular_computer/
	name = "modular computer"
	desc = "An advanced computer"

	var/battery_powered = 0											// Whether computer should be battery powered. It is set automatically
	use_power = 0
	var/hardware_flag = 0											// A flag that describes this device type
	var/last_power_usage = 0										// Power usage during last tick

	// Modular computers can run on various devices. Each DEVICE (Laptop, Console, Tablet,..)
	// must have it's own DMI file. Icon states must be called exactly the same in all files, but may look differently
	// If you create a program which is limited to Laptops and Consoles you don't have to add it's icon_state overlay for Tablets too, for example.

	icon = null
	icon_state = null
	var/icon_state_unpowered = null									// Icon state when the computer is turned off
	var/screen_icon_state_menu = "menu"								// Icon state overlay when the computer is turned on, but no program is loaded that would override the screen.
	var/max_hardware_size = 0										// Maximal hardware size. Currently, tablets have 1, laptops 2 and consoles 3. Limits what hardware types can be installed.
	var/steel_sheet_cost = 10										// Amount of steel sheets refunded when disassembling an empty frame of this computer.

	var/base_active_power_usage = 100								// Power usage when the computer is open (screen is active) and can be interacted with. Remember hardware can use power too.
	var/base_idle_power_usage = 10									// Power usage when the computer is idle and screen is off (currently only applies to laptops)

	var/obj/item/weapon/computer_hardware/tesla_link/tesla_link		// Tesla Link component of this computer. Allows remote charging from nearest APC.

	var/obj/item/modular_computer/processor/cpu = null				// CPU that handles most logic while this type only handles power and other specific things.



/obj/machinery/modular_computer/get_persistent_metadata()
	var/list/computer_data = list()
	if(cpu)
		var/obj/item/modular_computer/processor/the_cpu = cpu
		computer_data["cpu"] = the_cpu.type

		if(the_cpu.card_slot)
			var/obj/the_card_slot = the_cpu.card_slot
			computer_data["card_slot"] = the_card_slot.type
		if(the_cpu.battery_module)
			var/obj/the_battery_module = the_cpu.battery_module
			computer_data["battery_module"] = the_battery_module.type
		if(the_cpu.network_card)
			var/obj/the_network = the_cpu.network_card
			computer_data["network_card"] = the_network.type
		if(the_cpu.hard_drive)
			var/obj/item/weapon/computer_hardware/hard_drive/the_hard_drive = the_cpu.hard_drive
			computer_data["hard_drive"] = the_hard_drive.type

			var/list/all_prgms = list()
			for(var/datum/computer_file/program/prg in the_hard_drive.stored_files)
				all_prgms += prg.type

			if(!isemptylist(all_prgms))
				computer_data["programs"] = all_prgms

		if(the_cpu.nano_printer)
			var/obj/the_nano_printer = the_cpu.nano_printer
			computer_data["nano_printer"] = the_nano_printer.type

	if(tesla_link)
		var/obj/the_tesla_link = tesla_link
		computer_data["tesla_link"] = the_tesla_link.type

	return computer_data

/obj/machinery/modular_computer/load_persistent_metadata(computer_data)
	if(!computer_data)
		return FALSE

	if(computer_data["cpu"])
		var/new_cpu = computer_data["cpu"]
		cpu = new new_cpu(src)

		if(computer_data["network_card"])
			var/new_net = computer_data["network_card"]
			cpu.network_card = new new_net(src)
		if(computer_data["hard_drive"])
			var/new_hard_drive = computer_data["hard_drive"]
			cpu.hard_drive = new new_hard_drive(src)

			if(computer_data["programs"])
				var/list/all_programs = computer_data["programs"]
				cpu.hard_drive.stored_files = list()

				for(var/restored_program in all_programs)
					var/rest_prg = new restored_program(src)
					cpu.hard_drive.stored_files += rest_prg

		if(computer_data["card_slot"])
			var/new_card_slot = computer_data["card_slot"]
			cpu.card_slot = new new_card_slot(src)

		if(computer_data["battery_module"])
			var/new_battery_module = computer_data["battery_module"]
			cpu.battery_module = new new_battery_module(src)

		if(computer_data["nano_printer"])
			var/new_nano_printer = computer_data["nano_printer"]
			cpu.nano_printer = new new_nano_printer(src)


	if(computer_data["tesla_link"])
		var/new_tesla_link = computer_data["tesla_link"]
		tesla_link = new new_tesla_link(src)
	return TRUE


/obj/machinery/modular_computer/emag_act(var/remaining_charges, var/mob/user)
	return cpu ? cpu.emag_act(remaining_charges, user) : 0

/obj/machinery/modular_computer/update_icon()
	icon_state = icon_state_unpowered
	overlays.Cut()

	if(!cpu || !cpu.enabled)
		return
	if(cpu.active_program)
		overlays.Add(cpu.active_program.program_icon_state ? cpu.active_program.program_icon_state : screen_icon_state_menu)
	else
		overlays.Add(screen_icon_state_menu)

// Eject ID card from computer, if it has ID slot with card inside.
/obj/machinery/modular_computer/verb/eject_id()
	set name = "Eject ID"
	set category = "Object"
	set src in view(1)

	if(cpu)
		cpu.eject_id()

/obj/machinery/modular_computer/New()
	..()
	cpu = new(src)

// On-click handling. Turns on the computer if it's off and opens the GUI.
/obj/machinery/modular_computer/attack_hand(mob/user)
	if(cpu)
		cpu.attack_self(user) // CPU is an item, that's why we route attack_hand to attack_self

// Process currently calls handle_power(), may be expanded in future if more things are added.
/obj/machinery/modular_computer/process()
	if(cpu)
		// Keep names in sync.
		cpu.name = src.name
		cpu.process(1)

// Checks all hardware pieces to determine if name matches, if yes, returns the hardware piece, otherwise returns null
/obj/machinery/modular_computer/proc/find_hardware_by_name(var/N)
	if(tesla_link && (tesla_link.name == N))
		return tesla_link
	return null

// Used in following function to reduce copypaste
/obj/machinery/modular_computer/proc/power_failure()
	if(cpu && cpu.enabled) // Shut down the computer
		visible_message("<span class='danger'>\The [src]'s screen flickers [cpu.battery_module ? "\"BATTERY CRITICAL\"" : "\"EXTERNAL POWER LOSS\""] warning as it shuts down unexpectedly.</span>")
		if(cpu)
			cpu.kill_program(1)
			cpu.enabled = 0
		battery_powered = 0
		update_icon()
	stat |= NOPOWER

// Called by cpu item's process() automatically, handles our power interaction.
/obj/machinery/modular_computer/proc/handle_power()
	if(cpu.battery_module && cpu.battery_module.battery.charge <= 0) // Battery-run but battery is depleted.
		power_failure()
		return 0
	else if(!cpu.battery_module && (!powered() || !tesla_link || !tesla_link.enabled)) // Not battery run, but lacking APC connection.
		power_failure()
		return 0
	else if(stat & NOPOWER)
		stat &= ~NOPOWER

	if(cpu.battery_module && cpu.battery_module.battery.charge)
		battery_powered = 1
	else
		battery_powered = 0

	var/power_usage = cpu.screen_on ? base_active_power_usage : base_idle_power_usage
	for(var/obj/item/weapon/computer_hardware/CH in src.cpu.get_all_components())
		if(CH.enabled)
			power_usage += CH.power_usage

	// Wireless APC connection exists.
	if(tesla_link && tesla_link.enabled)
		idle_power_usage = power_usage
		active_power_usage = idle_power_usage + 100 	// APCLink only charges at 100W rate, but covers any power usage.
		use_power = 1
		// Battery is not fully charged. Begin slowly recharging.
		if(cpu.battery_module && (cpu.battery_module.battery.charge < cpu.battery_module.battery.maxcharge))
			use_power = 2

		if(cpu.battery_module && powered() && (use_power == 2)) // Battery charging itself
			cpu.battery_module.battery.give(100 * CELLRATE)
		else if(cpu.battery_module && !powered()) // Unpowered, but battery covers the usage.
			cpu.battery_module.battery.use(idle_power_usage * CELLRATE)

	else	// No wireless connection run only on battery.
		use_power = 0
		if (cpu.battery_module)
			cpu.battery_module.battery.use(power_usage * CELLRATE)
	cpu.last_power_usage = power_usage

// Modular computers can have battery in them, we handle power in previous proc, so prevent this from messing it up for us.
/obj/machinery/modular_computer/power_change()
	if(battery_powered)
		return
	else
		..()

/obj/machinery/modular_computer/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if(cpu)
		return cpu.attackby(W, user)
	return ..()
