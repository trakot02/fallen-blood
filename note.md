# Note

## Nomi strutture

I tipi di allocatori disponibili sono:

| Tipo    | Allocazione         | Deallocazione           |
| ------- | ------------------- | ----------------------- |
| `empty` | Non supportata      | Non supportata          |
| `stack` | Libera              | Solo ultima allocazione |
| `bump`  | Libera              | Non supportata          |
| `pool`  | Dimensione limitata | Libera                  |

I tipi di contenitori disponibili sono:

- `list` (es. `Array_List`)
- `stack`
- `queue`
- `map` (es. `Array_Map`)
- `set`
- `bag`
- `tree`
- `graph`

## Orientamento ai dati

### Dimensioni dei contenitori

I contenitori occupano più memoria in quanto occorrono più puntatori. Si possono risparmiare dei byte raggruppando dati che vengono usati sempre insieme all'interno di `struct` e quindi in un unico puntatore; questo dovrebbe migliorare l'utilizzo della cache.

### Numero di allocazioni

Sono necessarie più allocazioni, che devono comunque formare un'operazione atomica.

> `TODO:` Potrebbe essere utile chiedere agli allocatori se sono in grado di soddisfare la richiesta in anticipo.

La memoria non dovrebbe frammentarsi in quanto sono allocazioni diverse ma hanno lo stesso ciclo di vita, e dato che gli elementi generalmente non necessitano di padding, si dovrebbe risparmiare qualche byte.

### Ordine delle deallocazioni

Per il tipo di allocatore a `stack`, l'ordine delle deallocazioni deve essere inverso a quello delle allocazioni; siccome tutti gli altri metodi non necessitano di un particolare ordine: i puntatori **devono** essere deallocati in ordine contrario a quello con cui si sono allocati.

### Allineamento

Per gli allocatori come quello a `pool`, le allocazioni vengono sempre allineate a `16` così da soddisfare qualsiasi richiesta.

## Da adattare

Note implementative:

- I gruppi sono gestiti da una struttura dove accedendo per indice si ottiene il gruppo, poi tutte le seguenti strutture operano sull'indice da usare nella lista

- Gli identificatori degli attori gestiti da una struttura che li rilascia e ne tiene traccia (skypjack entt)

Organizzazione generale:

```cpp
using Actor_Id = u32; // 4 Mld attori.
using Trait_Id = u16; // 65'000 tratti.
using Group_Id = u32; // 4 Mld combinazioni di tratti.

// Insieme dei tratti.
using Trait_Set = Bit_Set<Trait_Id>;

// Ogni gruppo possiede il proprio insieme dei tratti, una lista
// dove sono contenute le colonne e degli archi per poter aggiungere
// o togliere un tratto ad un'entità rapidamente.

// Lista di un tipo di tratto non specificato.
struct Column {
	// ...
};

// Gruppo di attori.
struct Group {
	// Insieme dei tratti del gruppo.
    Trait_Set type;

    // Contenitore dei tratti del gruppo.
    List<Column> cols;

    // Indica il gruppo che possiede gli
    // stessi tratti, più un altro.
    Map<Trait_Id, Group_Id> next;

    // Indica il gruppo che possiede gli
    // stessi tratti, meno un altro.
    Map<Trait_Id, Group_Id> prev;
};

// Indica il gruppo che possiede un insieme di tratti.
static Map<Trait_Set, Group_Id> group_table;

// Indica il gruppo di un attore.
static Map<Actor_Id, Group_Id> actor_table;

// Indica i gruppi che contengono un tratto e
// in che colonna.
static Map<Trait_Id, Map<Group_Id, u32>> trait_table;
```
