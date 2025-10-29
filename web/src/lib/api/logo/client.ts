export type LogoResponse = {
  logo_url: string
}[]

export async function fetchLogo(name: string): Promise<string | null> {
  try {
    const response = await fetch(`/api/logo?q=${name}`)
    if (!response.ok) {
      console.error(`Failed to fetch logo for ${name}: ${response.statusText}`)
      return null
    }
    const data: LogoResponse = await response.json()
    if (data && data.length > 0 && data[0].logo_url) {
      return data[0].logo_url
    }
    return null
  } catch (error) {
    console.error(`Failed to fetch logo for ${name}`, error)
    return null
  }
}
