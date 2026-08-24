# Spanish (Mexico) localization: cross-localization for US search

## Why this exists

The US App Store does not only index English (U.S.) metadata. It indexes several
localizations, and each one carries its OWN 100-character keyword field. English (U.S.)
gets no priority over the others.

So adding Spanish (Mexico) gives us a second keyword field that is indexed for US
users. It roughly doubles indexed keyword surface, costs nothing, needs no new build,
and stays editable after release.

## The split, and why

- **Name and subtitle are VISIBLE**, so they are written in real Spanish. They serve
  Mexican users properly and they earn us Spanish search terms in the Mexican storefront.
- **The keyword field is INVISIBLE**, so it is filled with ENGLISH terms. Nobody ever
  reads it, and it is the field the US storefront indexes.

That is the whole trick: localize what people see, and spend what they cannot see on
the market we actually want.

## How to add it

App Store Connect > the app > Distribution / App Store tab > language dropdown at the
top of the page > **Add Language** > **Spanish (Mexico)**. That creates a full set of
empty fields. Fill only the four below. Leave screenshots empty and they inherit from
English automatically.

---

## App Name

```
Yolkling: Mascota Virtual
```
(25 / 30 characters)

"mascota virtual" is the highest-volume Spanish term for this category. The brand stays
first so the listing is recognisably the same app across localizations.

---

## Subtitle

```
hábitos sanos, criatura tierna
```
(30 / 30 characters)

Chosen over warmer phrasings because it is denser: four indexed Spanish terms
(hábitos, sanos, criatura, tierna) instead of two plus filler words.

---

## Keywords

Comma-separated, no spaces. Paste exactly. This is ENGLISH on purpose. See above.

```
anxiety,stress,calm,routine,daily,streak,detox,screentime,widget,pomodoro,timer,diary,companion,zen
```
(99 / 100 characters)

**Zero overlap with the English listing.** Apple credits a keyword once no matter how
many fields it appears in, so every term here is new surface. Nothing from the en-US
title, subtitle or keyword field is repeated.

**Every term is defensible against a real feature**, which matters because Apple rejects
keywords unrelated to the app:

| term | backed by |
|---|---|
| screentime, detox | the Screen Time integration and focus sessions |
| pomodoro, timer | focus sessions with a Live Activity |
| widget | the `YolklingWidgets` target |
| streak, routine, daily | care streaks and the daily check-in |
| diary | the private check-in record |
| anxiety, stress, calm, zen | the wellbeing positioning, same as the category |
| companion | the creature itself |

**New phrases this unlocks:** anxiety relief pet, daily routine tracker, screen time
detox, focus timer, self care companion, streak tracker, calm pet.

---

## Promotional Text

```
gratis, todo. incuba una criatura única y hazla crecer viviendo bien: pasos, sueño y tiempo lejos del teléfono. colecciona, decora y visita a tus amigos.
```
(151 / 170 characters)

---

## Description

```
Yolkling es una mascota virtual que crece cuando te cuidas en la vida real. tus pasos, tu sueño y tu tiempo lejos del teléfono alimentan a tu yolk, y vas coleccionando nuevos yolks y vistiéndolos.

gratis, todo. sin anuncios, y la única moneda son los Yolks, que ganas por cuidarte. los Yolks nunca están a la venta: no hay forma de comprarlos a ningún precio.

incuba
tu yolk es único. elige su color y su estilo, míralo salir del cascarón, y es tuyo. hay 203 especies con nombre por descubrir en cuatro familias, así que con la que empiezas es solo la primera.

crece viviendo
conecta Apple Health si quieres, y tus días reales alimentan a tu yolk. los pasos y el sueño lo ayudan a crecer, poco a poco, durante semanas, de pequeño a adulto. es completamente opcional. la app funciona por completo sin acceso a Health, y nada de tu día sale nunca de tu dispositivo para que esto ocurra.

deja el teléfono
inicia una sesión de concentración cuando quieras tiempo lejos de la pantalla. tu yolk descansa y brilla mientras no estás, una Live Activity te acompaña en la pantalla de bloqueo, y ganas Yolks al terminar. esta es la versión honesta del tiempo de pantalla: tú eliges alejarte, y tu yolk está más feliz por ello.

registra, gana, colecciona
un check-in diario y tranquilo te pregunta cómo estás, define el ánimo de tu yolk, y construye un registro privado solo para ti. gana Yolks con los check-ins y las sesiones de concentración, y gástalos en la tienda y el clóset en gorros, lentes, bufandas, colores raros y decoración para el cuarto de tu yolk. sin gacha, sin cajas de botín, sin trucos. compras exactamente lo que quieres.

amigos, con calma
agrega amigos con un código para compartir o escaneando un QR, deja que sus yolks visiten al tuyo, y manden postales de ida y vuelta. invita a un amigo con tu código de parvada fundadora y los dos reciben una especie fundadora. sin feeds, sin contadores de seguidores, sin likes. solo la gente que de verdad conoces.

honesto por diseño
sin anuncios. sin rastreo. tu historial de ánimo y tu día se quedan en tu dispositivo. hay un widget para la pantalla de inicio para que tu yolk esté a un vistazo, y una cuenta real que es tuya, con los controles que la acompañan.

si quieres apoyarlo
hay una suscripción opcional, Yolkling Plus. agrega un brillo de supporter en tu yolk y un puñado pequeño de Yolks cada mes, y eso es todo lo que hace. cada especie, cada gorro, cada función se puede alcanzar sin ella. lo único que no puedes ganar es el brillo, y ese es justo el punto: dice que elegiste mantener esto vivo.

hecho por una sola persona que quería una mascota que apoye a la persona real que eres.
```

Faithful translation of the English description, including the 203 species count and
every honesty claim (no ads, no tracking, Yolks never for sale, Health optional). Do not
paraphrase these: they are the same claims App Review will check against the build.

---

## Do NOT fill these for Spanish

- **Screenshots.** Leave empty and they inherit from English. Uploading a second set of
  16 buys nothing and doubles the surface that has to stay in sync.
- **What's New.** Not shown for a 1.0 release.
- **URLs.** Support, marketing and privacy stay the same.

---

## If you want to be more aggressive later

Everything above keeps the visible Spanish fields in Spanish, which is the defensible
choice while Mexico is a live storefront. The aggressive version puts ENGLISH in the
Spanish name and subtitle too, buying roughly 55 more indexed English characters for US
search at the cost of showing English to Mexican users. Worth revisiting once analytics
show where installs actually come from. Not worth guessing at now.
