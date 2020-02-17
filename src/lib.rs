#![feature(lang_items)]
#![no_std] // // don't link the Rust standard library

use core::panic::PanicInfo;

#[lang = "eh_personality"]
extern "C" fn eh_personality() {}

#[panic_handler] // This function is called on panic
extern "C" fn rust_begin_panic(info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern fn kmain() -> ! {
    
    unsafe {
        let vga = 0xb8000 as *mut u64;
        *vga = 0x2f592f412f4b2f4f;
        };
    loop{}
}
