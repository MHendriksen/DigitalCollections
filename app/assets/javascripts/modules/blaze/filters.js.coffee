kor.filter('translate', ["korTranslate", (korTranslate) ->
  return (input, options = {}) -> korTranslate.translate(input, options)
])

kor.filter('capitalize', [ ->
  return (input) ->
    try
      input[0..0].toUpperCase() + input[1..-1]
    catch erro
      ""
])

kor.filter('strftime', [ ->
  return (input, format) ->
    try
      if !(input instanceof Date)
        input = new Date(input)
        
      result = new FormattedDate(input)
      result.strftime format
    catch error
      ""
])

kor.filter('human_bool', [ ->
  return (input) ->
    if input then 'ja' else 'nein'
])

kor.filter('human_size', [ ->
  return (input) ->
    if input < 1024
      return "#{input} B"
    if input < 1024 * 1024
      return "#{Math.round(input / 1024 * 100) / 100} KB"
    if input < 1024 * 1024 * 1024
      return "#{Math.round(input / (1024 * 1024) * 100) / 100} MB"
    if input < 1024 * 1024 * 1024 * 1024
      return "#{Math.round(input / (1024 * 1024 * 1024) * 100) / 100} GB"
])

kor.filter('image_size', [ ->
  return (input, size) ->
    if input then input.replace(/preview/, size) else ""
])