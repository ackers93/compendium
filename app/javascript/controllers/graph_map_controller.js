import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

// Force-directed connection graph (Obsidian-style Map).
export default class extends Controller {
  static targets = ["canvas", "typeToggle", "empty"]
  static values = { graph: Object }

  connect() {
    this.hiddenTypes = new Set()
    this.dragged = false
    this.resizeObserver = new ResizeObserver(() => this.resize())
    this.resizeObserver.observe(this.element)
    this.render()
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.simulation?.stop()
    this.simulation = null
  }

  toggleType(event) {
    const type = event.currentTarget.dataset.type
    if (!type) return

    if (event.currentTarget.checked) {
      this.hiddenTypes.delete(type)
    } else {
      this.hiddenTypes.add(type)
    }
    this.applyVisibility()
  }

  render() {
    const svgEl = this.canvasTarget
    const rect = this.element.getBoundingClientRect()
    const width = Math.max(rect.width, 320)
    const height = Math.max(rect.height, 400)

    this.width = width
    this.height = height

    const svg = d3.select(svgEl)
    svg.selectAll("*").remove()
    svg.attr("viewBox", `0 0 ${width} ${height}`)
      .attr("width", "100%")
      .attr("height", "100%")

    const graph = this.graphValue || { nodes: [], edges: [] }
    this.nodes = (graph.nodes || []).map((n) => ({ ...n }))
    this.links = (graph.edges || []).map((e) => ({
      ...e,
      source: e.source,
      target: e.target
    }))

    if (this.nodes.length === 0) return

    const g = svg.append("g").attr("class", "graph-map__zoom")

    this.link = g.append("g")
      .attr("class", "graph-map__links")
      .selectAll("line")
      .data(this.links)
      .join("line")
      .attr("class", "graph-map__link")

    this.node = g.append("g")
      .attr("class", "graph-map__nodes")
      .selectAll("g")
      .data(this.nodes)
      .join("g")
      .attr("class", (d) => `graph-map__node graph-map__node--${this.typeClass(d.type)}`)
      .style("cursor", "pointer")
      .call(this.dragBehavior())
      .on("click", (event, d) => {
        if (this.dragged || event.defaultPrevented) return
        if (d.url) {
          if (window.Turbo) {
            window.Turbo.visit(d.url)
          } else {
            window.location.href = d.url
          }
        }
      })

    this.node.append("circle")
      .attr("r", (d) => d.size || 6)
      .attr("class", "graph-map__dot")

    this.node.append("title").text((d) => d.label || d.id)

    this.node.append("text")
      .attr("class", "graph-map__label")
      .attr("dy", (d) => (d.size || 6) + 10)
      .attr("text-anchor", "middle")
      .text((d) => this.shortLabel(d.label))

    this.simulation = d3.forceSimulation(this.nodes)
      .force("link", d3.forceLink(this.links).id((d) => d.id).distance(56).strength(0.4))
      .force("charge", d3.forceManyBody().strength(-120))
      .force("center", d3.forceCenter(width / 2, height / 2))
      .force("collision", d3.forceCollide().radius((d) => (d.size || 6) + 8))
      .on("tick", () => this.ticked())

    const zoom = d3.zoom()
      .scaleExtent([0.2, 4])
      .on("zoom", (event) => {
        g.attr("transform", event.transform)
      })

    svg.call(zoom)
    this.applyVisibility()
  }

  resize() {
    if (!this.simulation) return
    const rect = this.element.getBoundingClientRect()
    const width = Math.max(rect.width, 320)
    const height = Math.max(rect.height, 400)
    if (Math.abs(width - this.width) < 8 && Math.abs(height - this.height) < 8) return

    this.width = width
    this.height = height
    d3.select(this.canvasTarget).attr("viewBox", `0 0 ${width} ${height}`)
    this.simulation.force("center", d3.forceCenter(width / 2, height / 2))
    this.simulation.alpha(0.3).restart()
  }

  ticked() {
    this.link
      .attr("x1", (d) => d.source.x)
      .attr("y1", (d) => d.source.y)
      .attr("x2", (d) => d.target.x)
      .attr("y2", (d) => d.target.y)

    this.node.attr("transform", (d) => `translate(${d.x},${d.y})`)
  }

  applyVisibility() {
    if (!this.node) return

    const hidden = this.hiddenTypes
    const typedVisible = new Set(
      this.nodes.filter((n) => !hidden.has(n.type)).map((n) => n.id)
    )

    // Only keep nodes that still have an edge to another typed-visible node.
    const connectedVisible = new Set()
    this.links.forEach((d) => {
      const s = typeof d.source === "object" ? d.source.id : d.source
      const t = typeof d.target === "object" ? d.target.id : d.target
      if (typedVisible.has(s) && typedVisible.has(t)) {
        connectedVisible.add(s)
        connectedVisible.add(t)
      }
    })

    this.node.style("display", (d) => (connectedVisible.has(d.id) ? null : "none"))
    this.link.style("display", (d) => {
      const s = typeof d.source === "object" ? d.source.id : d.source
      const t = typeof d.target === "object" ? d.target.id : d.target
      return connectedVisible.has(s) && connectedVisible.has(t) ? null : "none"
    })

    if (this.hasEmptyTarget) {
      // Show empty state when nothing is visible under the current filters.
      this.emptyTarget.hidden = connectedVisible.size > 0
    }
  }

  dragBehavior() {
    const simulation = () => this.simulation

    return d3.drag()
      .on("start", (event, d) => {
        this.dragged = false
        if (!event.active) simulation().alphaTarget(0.3).restart()
        d.fx = d.x
        d.fy = d.y
      })
      .on("drag", (event, d) => {
        this.dragged = true
        d.fx = event.x
        d.fy = event.y
      })
      .on("end", (event, d) => {
        if (!event.active) simulation().alphaTarget(0)
        d.fx = null
        d.fy = null
        // Allow click shortly after a tiny drag; clear flag next tick for real drags
        if (this.dragged) {
          requestAnimationFrame(() => { this.dragged = false })
        }
      })
  }

  typeClass(type) {
    return String(type || "")
      .replace(/([a-z])([A-Z])/g, "$1-$2")
      .replace(/_/g, "-")
      .toLowerCase()
  }

  shortLabel(label) {
    if (!label) return ""
    return label.length > 28 ? `${label.slice(0, 26)}…` : label
  }
}
