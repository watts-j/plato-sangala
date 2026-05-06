use std::path::Path;
use crate::device::CURRENT_DEVICE;
use crate::document::{open, Location};
use crate::framebuffer::{Framebuffer, Pixmap};
use crate::font::{Fonts, font_from_style, NORMAL_STYLE};
use crate::view::{View, Event, Hub, Bus, Id, ID_FEEDER, RenderQueue};
use crate::geom::Rectangle;
use crate::color::{WHITE, TEXT_NORMAL};
use crate::context::Context;

// Single view that paints the home landing page (image on top, welcome
// text below) when the active library is intrinsically empty. Used as
// a child of Shelf instead of separate Image + Label views so the
// welcome state is rebuilt as one unit on every Shelf::update and so
// the inert Label below the image doesn't eat taps via its default
// tap-handling behavior.
pub struct WelcomeScreen {
    id: Id,
    rect: Rectangle,
    children: Vec<Box<dyn View>>,
    image_rect: Rectangle,
    label_rect: Rectangle,
    pixmap: Pixmap,
    text: String,
}

impl WelcomeScreen {
    pub fn try_new<P: AsRef<Path>>(rect: Rectangle, image_rect: Rectangle, label_rect: Rectangle,
                                    image_path: P, text: String) -> Option<Self> {
        let mut doc = open(image_path.as_ref())?;
        let (src_w, src_h) = doc.dims(0)?;
        let scale = (image_rect.width() as f32 / src_w)
            .min(image_rect.height() as f32 / src_h);
        let (pixmap, _) = doc.pixmap(Location::Exact(0), scale, CURRENT_DEVICE.color_samples())?;
        Some(WelcomeScreen {
            id: ID_FEEDER.next(),
            rect,
            children: Vec::new(),
            image_rect,
            label_rect,
            pixmap,
            text,
        })
    }
}

impl View for WelcomeScreen {
    fn handle_event(&mut self, _evt: &Event, _hub: &Hub, _bus: &mut Bus,
                    _rq: &mut RenderQueue, _context: &mut Context) -> bool {
        false
    }

    fn render(&self, fb: &mut dyn Framebuffer, rect: Rectangle, fonts: &mut Fonts) {
        // Clear the dirty area within our rect.
        if let Some(r) = self.rect.intersection(&rect) {
            fb.draw_rectangle(&r, WHITE);
        }

        // Render the (already pre-scaled) pixmap, centered in image_rect.
        let pw = self.pixmap.width as i32;
        let ph = self.pixmap.height as i32;
        let x0 = self.image_rect.min.x + (self.image_rect.width() as i32 - pw) / 2;
        let y0 = self.image_rect.min.y + (self.image_rect.height() as i32 - ph) / 2;
        let pixmap_rect = rect![x0, y0, x0 + pw, y0 + ph];
        if let Some(r) = pixmap_rect.intersection(&rect) {
            let frame = r - pt!(x0, y0);
            fb.draw_framed_pixmap(&self.pixmap, &frame, r.min);
        }

        // Render text only if the label area is dirty.
        if !self.text.is_empty() && self.label_rect.intersection(&rect).is_some() {
            let dpi = CURRENT_DEVICE.dpi;
            let font = font_from_style(fonts, &NORMAL_STYLE, dpi);
            let x_height = font.x_heights.0 as i32;
            let plan = font.plan(&self.text, Some(self.label_rect.width() as i32), None);
            let dx = (self.label_rect.width() as i32 - plan.width) / 2;
            let dy = (self.label_rect.height() as i32 - x_height) / 2;
            let pt = pt!(self.label_rect.min.x + dx, self.label_rect.max.y - dy);
            font.render(fb, TEXT_NORMAL[1], &plan, pt);
        }
    }

    fn rect(&self) -> &Rectangle {
        &self.rect
    }

    fn rect_mut(&mut self) -> &mut Rectangle {
        &mut self.rect
    }

    fn children(&self) -> &Vec<Box<dyn View>> {
        &self.children
    }

    fn children_mut(&mut self) -> &mut Vec<Box<dyn View>> {
        &mut self.children
    }

    fn id(&self) -> Id {
        self.id
    }
}
