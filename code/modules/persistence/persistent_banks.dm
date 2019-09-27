
/mob/living/carbon/human/proc/save_character_money()

	mind.initial_account.money = Clamp(mind.initial_account.money, -999999, 999999)


	mind.prefs.expenses = mind.initial_account.expenses

	mind.prefs.money_balance = mind.initial_account.money
	mind.prefs.bank_pin = mind.initial_account.remote_access_pin
	mind.prefs.bank_no = mind.initial_account.account_number

	mind.initial_account.save_persistent_account()

	return 1

/datum/money_account/proc/save_persistent_account()
	var/full_path = "data/persistent/banks/[account_number].sav"
	if(!full_path)			return 0
	if(!fexists(full_path)) return 0

	var/savefile/S = new /savefile(full_path)
	if(!S)					return 0

	S.cd = "/"

	S["owner_name"] << owner_name
	S["money"] << money
	S["account_number"] << account_number
	S["remote_access_pin"] << remote_access_pin
	S["expenses"] << expenses
	S["transaction_log"] << transaction_log
	S["suspended"] << suspended
	S["security_level"] << security_level

	return 1

/datum/money_account/proc/make_persistent() // for existing accounts
	make_new_persistent_account(owner_name, account_number, money, remote_access_pin, expenses, transaction_log, suspended, security_level)

/proc/make_new_persistent_account(var/owner, var/acc_no, var/money, var/pin, var/expenses, var/transaction_logs, var/suspend, var/security_level)
	var/full_path = "data/persistent/banks/[acc_no].sav"
	if(!full_path)			return 0
	if(fexists(full_path)) return 0

	var/savefile/S = new /savefile(full_path)
	if(!S)					return 0
	S.cd = "/"

	S["owner_name"] << owner
	S["money"] << money
	S["account_number"] << acc_no
	S["remote_access_pin"] << pin
	S["expenses"] << expenses
	S["transaction_log"] << transaction_logs
	S["suspended"] << suspend
	S["security_level"] << security_level

	return 1

/proc/persist_adjust_balance(var/acc_no, var/amount)
	var/full_path = "data/persistent/banks/[acc_no].sav"

	if(!full_path)			return 0
	if(!fexists(full_path)) return 0

	if(!config.canonicity) return 0
	var/savefile/S = new /savefile(full_path)
	if(!S)					return 0
	S.cd = "/"

	var/transferred_money

	S["money"] >> transferred_money

	transferred_money += amount

	S["money"] << transferred_money

	return 1

/proc/get_persistent_acc_balance(var/acc_no)
	var/full_path = "data/persistent/banks/[acc_no].sav"

	if(!full_path)			return 0
	if(!fexists(full_path)) return 0

	var/savefile/S = new /savefile(full_path)
	if(!S)					return 0
	S.cd = "/"

	var/transferred_money

	S["money"] >> transferred_money

	return

/proc/persist_set_balance(var/acc_no, var/amount)
	var/full_path = "data/persistent/banks/[acc_no].sav"

	if(!full_path)			return 0
	if(!fexists(full_path)) return 0

	if(!config.canonicity) return 0
	var/savefile/S = new /savefile(full_path)
	if(!S)					return 0
	S.cd = "/"

	var/transferred_money

	S["money"] >> transferred_money

	transferred_money = amount

	S["money"] << transferred_money

	return 1


/proc/persist_add_log(var/acc_no, var/log)
	var/full_path = "data/persistent/banks/[acc_no].sav"

	if(!full_path)			return 0
	if(!fexists(full_path)) return 0

	if(!config.canonicity) return 0

	var/savefile/S = new /savefile(full_path)
	if(!S)					return 0
	S.cd = "/"

	var/transaction_log

	S["transaction_log"] >> transaction_log

	transaction_log += log

	S["transaction_log"] << transaction_log

	return 1


/proc/persist_acc(var/acc_no)
	var/full_path = "data/persistent/banks/[acc_no].sav"

	if(!full_path)			return 0
	if(!fexists(full_path)) return 0

	var/savefile/S = new /savefile(full_path)
	if(!S)					return 0

	return 1

