;; LoanProt Flash Loan Protocol
;; Production-grade flash loan contract with security auditing

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-certificate-exists (err u102))
(define-constant err-certificate-not-found (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-invalid-principal (err u105))

;; Data Variables
(define-data-var next-certificate-id uint u1)

;; Data Maps
(define-map authorized-institutions principal bool)
(define-map certificates 
  uint 
  {
    institution: principal,
    recipient: principal,
    certificate-hash: (buff 32),
    issue-date: uint,
    expiry-date: (optional uint),
    certificate-type: (string-ascii 50),
    metadata: (string-ascii 500)
  }
)

(define-map recipient-certificates principal (list 100 uint))
(define-map institution-certificates principal (list 1000 uint))

;; Input validation helpers
(define-private (is-valid-principal (addr principal))
  (not (is-eq addr 'SP000000000000000000002Q6VF78))
)

(define-private (is-valid-hash (hash (buff 32)))
  (> (len hash) u0)
)

(define-private (is-valid-string (str (string-ascii 50)))
  (and (> (len str) u0) (<= (len str) u50))
)

(define-private (is-valid-metadata (meta (string-ascii 500)))
  (<= (len meta) u500)
)

;; Authorization Functions
(define-public (authorize-institution (institution principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-valid-principal institution) err-invalid-principal)
    (ok (map-set authorized-institutions institution true))
  )
)

(define-public (revoke-institution (institution principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-valid-principal institution) err-invalid-principal)
    (ok (map-delete authorized-institutions institution))
  )
)

;; Certificate Issuance
(define-public (issue-certificate 
  (recipient principal)
  (certificate-hash (buff 32))
  (expiry-date (optional uint))
  (certificate-type (string-ascii 50))
  (metadata (string-ascii 500))
)
  (let 
    (
      (certificate-id (var-get next-certificate-id))
      (current-block-height block-height)
    )
    (asserts! (default-to false (map-get? authorized-institutions tx-sender)) err-not-authorized)
    (asserts! (is-valid-principal recipient) err-invalid-principal)
    (asserts! (is-valid-hash certificate-hash) err-invalid-input)
    (asserts! (is-valid-string certificate-type) err-invalid-input)
    (asserts! (is-valid-metadata metadata) err-invalid-input)

    ;; Validate expiry date if provided
    (match expiry-date
      expiry (asserts! (> expiry current-block-height) err-invalid-input)
      true
    )

    ;; Store certificate
    (map-set certificates certificate-id {
      institution: tx-sender,
      recipient: recipient,
      certificate-hash: certificate-hash,
      issue-date: current-block-height,
      expiry-date: expiry-date,
      certificate-type: certificate-type,
      metadata: metadata
    })

    ;; Update recipient certificates list
    (map-set recipient-certificates 
      recipient
      (unwrap-panic (as-max-len? 
        (append (default-to (list) (map-get? recipient-certificates recipient)) certificate-id) 
        u100
      ))
    )

    ;; Update institution certificates list
    (map-set institution-certificates 
      tx-sender 
      (unwrap-panic (as-max-len? 
        (append (default-to (list) (map-get? institution-certificates tx-sender)) certificate-id) 
        u1000
      ))
    )

    ;; Increment certificate ID
    (var-set next-certificate-id (+ certificate-id u1))

    (ok certificate-id)
  )
)

;; Verification Functions
(define-read-only (verify-certificate (certificate-id uint))
  (map-get? certificates certificate-id)
)

(define-read-only (verify-certificate-hash (certificate-id uint) (provided-hash (buff 32)))
  (match (map-get? certificates certificate-id)
    certificate (is-eq (get certificate-hash certificate) provided-hash)
    false
  )
)

(define-read-only (is-certificate-valid (certificate-id uint))
  (match (map-get? certificates certificate-id)
    certificate 
      (match (get expiry-date certificate)
        expiry (< block-height expiry)
        true
      )
    false
  )
)

;; Query Functions
(define-read-only (get-recipient-certificates (recipient principal))
  (default-to (list) (map-get? recipient-certificates recipient))
)

(define-read-only (get-institution-certificates (institution principal))
  (default-to (list) (map-get? institution-certificates institution))
)

(define-read-only (is-institution-authorized (institution principal))
  (default-to false (map-get? authorized-institutions institution))
)

(define-read-only (get-certificate-count)
  (- (var-get next-certificate-id) u1)
)

;; Batch verification for employers
(define-read-only (batch-verify-certificates (certificate-ids (list 20 uint)))
  (map verify-certificate certificate-ids)
)
