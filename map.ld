MEMORY
{
    FLASH : ORIGIN = 0x0, LENGTH = 128k
}


SECTIONS
{
    .text : {
        *(.vectors)
        *(.text)
    } > FLASH
}