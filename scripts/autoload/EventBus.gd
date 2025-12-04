# scripts/autoload/EventBus.gd
extends Node

# Сигналы для различных событий
signal unit_selected(unit)
signal unit_died(unit)
signal building_constructed(building)
signal building_destroyed(building)
signal resource_depleted(resource_node)
signal enemy_raid_started()
signal day_passed()
signal season_changed(season)

# Можно добавлять новые сигналы по мере необходимости