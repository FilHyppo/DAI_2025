globals [
  price-history ; lista per tracciare i prezzi medi nel tempo
  unsold-houses ; conteggio delle case invendute
  avg-price-per-sqm ; Prezzo medio al metro quadrato
  sales-rate ; Tasso di vendita delle case
]

turtles-own [
  budget ; per gli acquirenti
  square-meters ; preferenze degli acquirenti per la square-meters
]

patches-own [
  house ; true se il patch ha una casa sopra
  price ; prezzo di un immobile
  size_imm ; square-meters dell'immobile

]

; --- SETUP ---

to setup
  clear-all
  set-default-shape turtles "person"
  setup-houses
  setup-buyers
  set price-history []
  set sales-rate 0 ; inizializza il tasso di vendita
  reset-ticks
end

; Crea le case sui patch

to setup-houses
  let cnt 0
  ask patches [
    ifelse cnt < tot-houses [ ; numero di patch che avranno case
      set house true
      set pcolor green
      set size_imm random 100 + 50 ; dimensione tra 50 e 150 m2
      set price size_imm * 100 ; prezzo iniziale proporzionale alla square-meters
      show (word "Creata una casa con prezzo iniziale: " price)
      set cnt cnt + 1
    ]
    ;else
    [
      set house false
    ]
  ]
end

; Crea gli acquirenti

to setup-buyers

  create-turtles tot-buyers [
    set budget random 15000 + 5000 ; budget tra 5.000 e 20.000
    set square-meters random 100 + 50 ; preferenza per una certa square-meters
    setxy random-xcor random-ycor
    show (word "Creato un acquirente con budget: " budget ", metri desiderati: " square-meters)
  ]
end




; --- GO ---
to go
  if not any? turtles [
    show "Non ci sono acquirenti. Simulazione terminata."
    stop
  ]
  let initial-houses count patches with [house] ; Numero di case all'inizio del tick
  ask turtles [ attempt-purchase ]
  let sold-houses initial-houses - count patches with [house] ; Case vendute nel tick
  update-sales-rate sold-houses initial-houses ; Aggiorna il tasso di vendita
  update-prices
  update-buyers
  create-new-houses
  create-new-buyers
  update-avg-price-per-sqm ; Calcola il prezzo medio al metro quadrato
  tick
end

; Aggiorna il tasso di vendita delle case

to update-sales-rate [sold-houses initial-houses]
  if initial-houses > 0 [
    set sales-rate (sold-houses / initial-houses) * 100 ; Calcola la percentuale
    show (word "Tasso di vendita: " sales-rate "%")
  ]
  if initial-houses = 0 [
    set sales-rate 0 ; Se non ci sono case iniziali, il tasso di vendita è 0
  ]
end

; Gli acquirenti cercano di acquistare case che rispettano il budget e le preferenze

to attempt-purchase
  let suitable-house one-of patches with [
    house and price <= [budget] of myself and abs(size_imm - [square-meters] of myself) <= size-tolerance
  ]
  if suitable-house != nobody [
    ; Acquisto completato
    ;show (word "Acquirente con budget " budget " ha acquistato una casa con prezzo " [price] of suitable-house)
    ask suitable-house [
      set house false
      set pcolor black ; Casa venduta, patch non più verde
      set price 0
      set size_imm 0
    ]
    die ; L'acquirente termina dopo l'acquisto
  ]
end

; I venditori aggiornano i prezzi a ribasso visto che non hanno venduto
to update-prices
  ask patches with [house] [
    let old-price price
    set price price * (1 - (price-reduction-rate / 100)) ; variazione compresa tra 1% e 15%
    ;show (word "Aggiornato prezzo da " old-price " a " price)
  ]
end

; I copratori incrementano il loro prezzo visto che non trovano case da comprare
to update-buyers
  ask turtles [
    let old-budget budget
    set budget budget * (1 + (budget-increase-rate / 100)) ; variazione casuale tra +1% e +15%
    ;show (word "Aggiornato prezzo da " old-budget " a " budget)
  ]
end


to update-avg-price-per-sqm
  let total-price sum [price] of patches with [house]
  let total-size sum [size_imm] of patches with [house]
  show (word "bbbtot-price: " total-price)
  show (word "bbbtot-size: " total-size)
  ifelse total-size > 0 [
    set avg-price-per-sqm total-price / total-size
    show (word "cccccccccavg-price-per-sqm: " avg-price-per-sqm)

  ] [
    set avg-price-per-sqm 1 ; Default se non ci sono case disponibili
    show (word "ccccccccc-przzo1aaaaaa: " avg-price-per-sqm)

  ]
end




to create-new-houses
  let new-houses floor (house-growth-rate / 100 * tot-houses)
  let created-houses 0

  ; Calcola il rapporto domanda/offerta
  let buyers-count count turtles
  let available-houses count patches with [house]
  let demand-supply-ratio ifelse-value ((available-houses > 0)) [
    buyers-count / available-houses
  ] [
    2 ; Default: rapporto neutro se non ci sono né case né acquirenti
  ]
  if demand-supply-ratio > 2[
    set demand-supply-ratio 2 ; in questo modo se il rapporto è molto alto avrò come massimo nel calcolo del fattore d'aumento un 100%
  ]

  ; Calcola il fattore di prezzo, limitato a +-20%
  let price-adjustment-factor ifelse-value (demand-supply-ratio < 1) [ ; se ho meno compratori che case il prezzo delle case deve diminuire
    1 - min list (1 - demand-supply-ratio) (max-price-adjustment / 100) ; Riduzione massima del 20%
  ] [
    1 + min list (demand-supply-ratio - 1) (max-price-adjustment / 100) ; Aumento massimo del 20%
  ]
  show (word "price-adjustment-factor: " price-adjustment-factor)

  ask patches with [not house] [
    if created-houses < new-houses [
      set house true
      set pcolor green
      set size_imm random 100 + 50 ; Dimensione tra 50 e 150 m2

      ; Prezzo basato sul prezzo medio al metro quadrato aggiornato

      set price avg-price-per-sqm * size_imm * price-adjustment-factor
      set created-houses created-houses + 1


      ;show (word "Nuova casa creata con prezzo: " price ", metratura: " size_imm)
    ]
  ]
end

to create-new-buyers
  let new-buyers floor (buyer-growth-rate / 100 * tot-buyers)

  ; Calcola il rapporto domanda/offerta
  let buyers-count count turtles
  let available-houses count patches with [house]
  let demand-supply-ratio ifelse-value ((available-houses > 0) and (buyers-count > 0)) [
    buyers-count / available-houses
  ] [
    1 ; Default: rapporto neutro se non ci sono né case né acquirenti
  ]
  if demand-supply-ratio > 2[
    set demand-supply-ratio 2 ; in questo modo se il rapporto è molto alto avrò come massimo nel calcolo del fattore d'aumento un 100%
  ]

  ; Calcola il fattore di budget, limitato a +-20%
  let budget-adjustment-factor ifelse-value (demand-supply-ratio < 1) [ ; se ho meno compratori che case il budget dei compratori deve diminuire
    1 - min list (1 - demand-supply-ratio) (max-budget-adjustment / 100) ; Riduzione massima del 20%
  ] [
    1 + min list (demand-supply-ratio - 1) (max-budget-adjustment / 100) ; Aumento massimo del 20%
  ]

  create-turtles new-buyers [
    set square-meters random 100 + 50 ; Preferenza per una certa metratura
    set budget budget + square-meters * 100 * budget-adjustment-factor ; aggiustamento budget
    setxy random-xcor random-ycor
    ;show (word "Creato un nuovo acquirente con budget: " budget ", preferenza per metratura: " square-meters)
  ]
end






;7. Soddisfazione degli Acquirenti
;Cosa tracciare: La percentuale di acquirenti che trovano una casa compatibile con le loro preferenze (metratura e budget).
;Perché è utile: Può indicare se il mercato è in grado di soddisfare le necessità degli acquirenti.

;9. Tasso di Creazione di Case e Acquirenti
;Cosa tracciare: Il numero di nuove case o acquirenti creati in ogni tick.
;Perché è utile: Può fornire un'idea del ritmo con cui il mercato si evolve.
