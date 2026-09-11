def find_table_and_list(mrdata):
    """MRData siempre trae una sola key de 'tabla' (RaceTable, StandingsTable, etc.)
    y dentro de esa tabla, una sola lista con los registros."""
    table_key = next(k for k, v in mrdata.items() if isinstance(v, dict))
    table = mrdata[table_key]
    list_key = next(k for k, v in table.items() if isinstance(v, list))
    return table[list_key]
