CLS     equ $0d6b ; https://skoolkid.github.io/rom/asm/0D6B.html
BORDCR  equ $5c48 ; https://skoolkid.github.io/rom/asm/5C48.html
ATTR_P  equ $5c8d ; https://skoolkid.github.io/rom/asm/5C8D.html

; Move stack out of the data range
    ld      sp, $f000

; Clear the screen
    xor     a
    ld      (ATTR_P), a
    ld      (BORDCR), a
    out     ($fe), a
    call    CLS

; Move the loader to a safe location
    ld      de, $0b         ; the offset of the block to be moved
                            ; relatively to the address after call minus 1
    inc     e               ; add 1 to reset the Z flag
    call    $1fc6           ; this is essentially ld HL, PC
    add     hl, de          ; now HL points to the begginning of the loader
    ld      de, $f000       ; destination
    ld      bc, end_loader-loader
    ldir
    jp      $f000

loader:
; Load the image
    ld      de, ($5cf4)     ; restore the FDD head position
    ld      bc, $0f05       ; load 15 sectors of compressed image
    ld      hl, $9c40       ; destination address (40000)
    call    $3d13           ;
    call    $9c40           ; decompress the image

; Load the data
    ld      de, ($5cf4)     ; restore the FDD head position
    ld      hl, $6000       ; destination address (24576)
    ld      bc, $8f05       ; load 143 sectors of data
    call    $3d13

    di

    ld      hl, $6000
    ld      de, $5b00
    ld      bc, $8ecf
    ldir

    jp      $5b00
end_loader:
